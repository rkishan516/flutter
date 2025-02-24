// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_key_embedder_responder.h"

#include <gtk/gtk.h>
#include <cinttypes>

#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/linux/fl_key_embedder_responder_private.h"
#include "flutter/shell/platform/linux/key_mapping.h"

constexpr uint64_t kMicrosecondsPerMillisecond = 1000;

static const FlutterKeyEvent kEmptyEvent{
    .struct_size = sizeof(FlutterKeyEvent),
    .timestamp = 0,
    .type = kFlutterKeyEventTypeDown,
    .physical = 0,
    .logical = 0,
    .character = nullptr,
    .synthesized = false,
};

// Look up a hash table that maps a uint64_t to a uint64_t.
//
// Returns 0 if not found.
//
// Both key and value should be directly hashed.
static uint64_t lookup_hash_table(GHashTable* table, uint64_t key) {
  return gpointer_to_uint64(
      g_hash_table_lookup(table, uint64_to_gpointer(key)));
}

static gboolean hash_table_find_equal_value(gpointer key,
                                            gpointer value,
                                            gpointer user_data) {
  return gpointer_to_uint64(value) == gpointer_to_uint64(user_data);
}

// Look up a hash table that maps a uint64_t to a uint64_t; given its key,
// find its value.
//
// Returns 0 if not found.
//
// Both key and value should be directly hashed.
static uint64_t reverse_lookup_hash_table(GHashTable* table, uint64_t value) {
  return gpointer_to_uint64(g_hash_table_find(
      table, hash_table_find_equal_value, uint64_to_gpointer(value)));
}

static uint64_t to_lower(uint64_t n) {
  constexpr uint64_t lower_a = 0x61;
  constexpr uint64_t upper_a = 0x41;
  constexpr uint64_t upper_z = 0x5a;

  constexpr uint64_t lower_a_grave = 0xe0;
  constexpr uint64_t upper_a_grave = 0xc0;
  constexpr uint64_t upper_thorn = 0xde;
  constexpr uint64_t division = 0xf7;

  // ASCII range.
  if (n >= upper_a && n <= upper_z) {
    return n - upper_a + lower_a;
  }

  // EASCII range.
  if (n >= upper_a_grave && n <= upper_thorn && n != division) {
    return n - upper_a_grave + lower_a_grave;
  }

  return n;
}

namespace {

typedef enum {
  STATE_LOGIC_INFERRENCE_UNDECIDED,
  STATE_LOGIC_INFERRENCE_NORMAL,
  STATE_LOGIC_INFERRENCE_REVERSED,
} StateLogicInferrence;

}

struct _FlKeyEmbedderResponder {
  GObject parent_instance;

  // Engine sending key events to.
  GWeakRef engine;

  // Internal record for states of whether a key is pressed.
  //
  // It is a map from Flutter physical key to Flutter logical key.  Both keys
  // and values are directly stored uint64s.  This table is freed by the
  // responder.
  GHashTable* pressing_records;

  // Internal record for states of whether a lock mode is enabled.
  //
  // It is a bit mask composed of GTK mode bits.
  guint lock_records;

  // Internal record for the last observed key mapping.
  //
  // It stores the physical key last seen during a key down event for a logical
  // key. It is used to synthesize modifier keys and lock keys.
  //
  // It is a map from Flutter logical key to physical key.  Both keys and
  // values are directly stored uint64s.  This table is freed by the responder.
  GHashTable* mapping_records;

  // The inferred logic type indicating whether the CapsLock state logic is
  // reversed on this platform.
  //
  // For more information, see #update_caps_lock_state_logic_inferrence.
  StateLogicInferrence caps_lock_state_logic_inferrence;

  // Record if any events has been sent during a
  // |fl_key_embedder_responder_handle_event| call.
  bool sent_any_events;

  // A static map from GTK modifier bits to #FlKeyEmbedderCheckedKey to
  // configure the modifier keys that needs to be tracked and kept synchronous
  // on.
  //
  // The keys are directly stored guints.  The values must be freed with g_free.
  // This table is freed by the responder.
  GHashTable* modifier_bit_to_checked_keys;

  // A static map from GTK modifier bits to #FlKeyEmbedderCheckedKey to
  // configure the lock mode bits that needs to be tracked and kept synchronous
  // on.
  //
  // The keys are directly stored guints.  The values must be freed with g_free.
  // This table is freed by the responder.
  GHashTable* lock_bit_to_checked_keys;

  // A static map generated by reverse mapping lock_bit_to_checked_keys.
  //
  // It is a map from primary physical keys to lock bits.  Both keys and values
  // are directly stored uint64s.  This table is freed by the responder.
  GHashTable* logical_key_to_lock_bit;

  GCancellable* cancellable;
};

static void fl_key_embedder_responder_dispose(GObject* object);

G_DEFINE_TYPE(FlKeyEmbedderResponder, fl_key_embedder_responder, G_TYPE_OBJECT)

// Initializes the FlKeyEmbedderResponder class methods.
static void fl_key_embedder_responder_class_init(
    FlKeyEmbedderResponderClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_key_embedder_responder_dispose;
}

// Initializes an FlKeyEmbedderResponder instance.
static void fl_key_embedder_responder_init(FlKeyEmbedderResponder* self) {
  self->cancellable = g_cancellable_new();
}

// Disposes of an FlKeyEmbedderResponder instance.
static void fl_key_embedder_responder_dispose(GObject* object) {
  FlKeyEmbedderResponder* self = FL_KEY_EMBEDDER_RESPONDER(object);

  g_cancellable_cancel(self->cancellable);

  g_weak_ref_clear(&self->engine);
  g_clear_pointer(&self->pressing_records, g_hash_table_unref);
  g_clear_pointer(&self->mapping_records, g_hash_table_unref);
  g_clear_pointer(&self->modifier_bit_to_checked_keys, g_hash_table_unref);
  g_clear_pointer(&self->lock_bit_to_checked_keys, g_hash_table_unref);
  g_clear_pointer(&self->logical_key_to_lock_bit, g_hash_table_unref);
  g_clear_object(&self->cancellable);

  G_OBJECT_CLASS(fl_key_embedder_responder_parent_class)->dispose(object);
}

// Creates a new FlKeyEmbedderResponder instance.
FlKeyEmbedderResponder* fl_key_embedder_responder_new(FlEngine* engine) {
  FlKeyEmbedderResponder* self = FL_KEY_EMBEDDER_RESPONDER(
      g_object_new(fl_key_embedder_responder_get_type(), nullptr));

  g_weak_ref_init(&self->engine, engine);

  self->pressing_records = g_hash_table_new(g_direct_hash, g_direct_equal);
  self->mapping_records = g_hash_table_new(g_direct_hash, g_direct_equal);
  self->lock_records = 0;
  self->caps_lock_state_logic_inferrence = STATE_LOGIC_INFERRENCE_UNDECIDED;

  self->modifier_bit_to_checked_keys =
      g_hash_table_new_full(g_direct_hash, g_direct_equal, NULL, g_free);
  initialize_modifier_bit_to_checked_keys(self->modifier_bit_to_checked_keys);

  self->lock_bit_to_checked_keys =
      g_hash_table_new_full(g_direct_hash, g_direct_equal, NULL, g_free);
  initialize_lock_bit_to_checked_keys(self->lock_bit_to_checked_keys);

  // Associate a logical key with its corresponding modifier bit.
  self->logical_key_to_lock_bit =
      g_hash_table_new(g_direct_hash, g_direct_equal);
  GHashTableIter iter;
  g_hash_table_iter_init(&iter, self->lock_bit_to_checked_keys);
  gpointer key, value;
  while (g_hash_table_iter_next(&iter, &key, &value)) {
    guint lock_bit = GPOINTER_TO_UINT(key);
    FlKeyEmbedderCheckedKey* checked_key =
        reinterpret_cast<FlKeyEmbedderCheckedKey*>(value);
    g_hash_table_insert(self->logical_key_to_lock_bit,
                        uint64_to_gpointer(checked_key->primary_logical_key),
                        GUINT_TO_POINTER(lock_bit));
  }

  return self;
}

static uint64_t apply_id_plane(uint64_t logical_id, uint64_t plane) {
  return (logical_id & kValueMask) | plane;
}

static uint64_t event_to_physical_key(FlKeyEvent* event) {
  auto found = xkb_to_physical_key_map.find(fl_key_event_get_keycode(event));
  if (found != xkb_to_physical_key_map.end()) {
    return found->second;
  }
  return apply_id_plane(fl_key_event_get_keycode(event), kGtkPlane);
}

static uint64_t event_to_logical_key(FlKeyEvent* event) {
  guint keyval = fl_key_event_get_keyval(event);
  auto found = gtk_keyval_to_logical_key_map.find(keyval);
  if (found != gtk_keyval_to_logical_key_map.end()) {
    return found->second;
  }
  // EASCII range
  if (keyval < 256) {
    return apply_id_plane(to_lower(keyval), kUnicodePlane);
  }
  // Auto-generate key
  return apply_id_plane(keyval, kGtkPlane);
}

static uint64_t event_to_timestamp(FlKeyEvent* event) {
  return kMicrosecondsPerMillisecond *
         static_cast<double>(fl_key_event_get_time(event));
}

// Returns a newly accocated UTF-8 string from fl_key_event_get_keyval(event)
// that must be freed later with g_free().
static char* event_to_character(FlKeyEvent* event) {
  gunichar unicodeChar = gdk_keyval_to_unicode(fl_key_event_get_keyval(event));
  glong items_written;
  gchar* result = g_ucs4_to_utf8(&unicodeChar, 1, NULL, &items_written, NULL);
  if (items_written == 0) {
    if (result != NULL) {
      g_free(result);
    }
    return nullptr;
  }
  return result;
}

// Sends a synthesized event to the framework with no demand for callback.
static void synthesize_simple_event(FlKeyEmbedderResponder* self,
                                    FlutterKeyEventType type,
                                    uint64_t physical,
                                    uint64_t logical,
                                    double timestamp) {
  FlutterKeyEvent out_event;
  out_event.struct_size = sizeof(out_event);
  out_event.timestamp = timestamp;
  out_event.type = type;
  out_event.physical = physical;
  out_event.logical = logical;
  out_event.character = nullptr;
  out_event.synthesized = true;
  self->sent_any_events = true;
  g_autoptr(FlEngine) engine = FL_ENGINE(g_weak_ref_get(&self->engine));
  if (engine != nullptr) {
    fl_engine_send_key_event(engine, &out_event, self->cancellable, nullptr,
                             nullptr);
  }
}

// Update the pressing record.
//
// If `logical_key` is 0, the record will be set as "released".  Otherwise, the
// record will be set as "pressed" with this logical key.  This function asserts
// that the key is pressed if the caller asked to release, and vice versa.
static void update_pressing_state(FlKeyEmbedderResponder* self,
                                  uint64_t physical_key,
                                  uint64_t logical_key) {
  if (logical_key != 0) {
    g_return_if_fail(lookup_hash_table(self->pressing_records, physical_key) ==
                     0);
    g_hash_table_insert(self->pressing_records,
                        uint64_to_gpointer(physical_key),
                        uint64_to_gpointer(logical_key));
  } else {
    g_return_if_fail(lookup_hash_table(self->pressing_records, physical_key) !=
                     0);
    g_hash_table_remove(self->pressing_records,
                        uint64_to_gpointer(physical_key));
  }
}

// Update the lock record.
//
// If `is_down` is false, this function is a no-op.  Otherwise, this function
// finds the lock bit corresponding to `physical_key`, and flips its bit.
static void possibly_update_lock_bit(FlKeyEmbedderResponder* self,
                                     uint64_t logical_key,
                                     bool is_down) {
  if (!is_down) {
    return;
  }
  const guint mode_bit = GPOINTER_TO_UINT(g_hash_table_lookup(
      self->logical_key_to_lock_bit, uint64_to_gpointer(logical_key)));
  if (mode_bit != 0) {
    self->lock_records ^= mode_bit;
  }
}

static void update_mapping_record(FlKeyEmbedderResponder* self,
                                  uint64_t physical_key,
                                  uint64_t logical_key) {
  g_hash_table_insert(self->mapping_records, uint64_to_gpointer(logical_key),
                      uint64_to_gpointer(physical_key));
}

// Synchronizes the pressing state of a key to its state from the event by
// synthesizing events.
static void synchronize_pressed_states(FlKeyEmbedderResponder* self,
                                       guint state,
                                       double timestamp) {
  GHashTableIter iter;
  g_hash_table_iter_init(&iter, self->modifier_bit_to_checked_keys);
  gpointer key, value;
  while (g_hash_table_iter_next(&iter, &key, &value)) {
    guint modifier_bit = GPOINTER_TO_UINT(key);
    FlKeyEmbedderCheckedKey* checked_key =
        reinterpret_cast<FlKeyEmbedderCheckedKey*>(value);

    // Each TestKey contains up to two logical keys, typically the left modifier
    // and the right modifier, that correspond to the same modifier_bit. We'd
    // like to infer whether to synthesize a down or up event for each key.
    //
    // The hard part is that, if we want to synthesize a down event, we don't
    // know which physical key to use. Here we assume the keyboard layout do not
    // change frequently and use the last physical-logical relationship,
    // recorded in #mapping_records.
    const uint64_t logical_keys[] = {
        checked_key->primary_logical_key,
        checked_key->secondary_logical_key,
    };
    const guint length = checked_key->secondary_logical_key == 0 ? 1 : 2;

    const bool any_pressed_by_state = (state & modifier_bit) != 0;

    bool any_pressed_by_record = false;

    // Traverse each logical key of this modifier bit for 2 purposes:
    //
    //  1. Perform the synthesization of release events: If the modifier bit is
    //  0
    //     and the key is pressed, synthesize a release event.
    //  2. Prepare for the synthesization of press events: If the modifier bit
    //  is
    //     1, and no keys are pressed (discovered here), synthesize a press
    //     event later.
    for (guint logical_key_idx = 0; logical_key_idx < length;
         logical_key_idx++) {
      const uint64_t logical_key = logical_keys[logical_key_idx];
      g_return_if_fail(logical_key != 0);
      const uint64_t pressing_physical_key =
          reverse_lookup_hash_table(self->pressing_records, logical_key);
      const bool this_key_pressed_before_event = pressing_physical_key != 0;

      any_pressed_by_record =
          any_pressed_by_record || this_key_pressed_before_event;

      if (this_key_pressed_before_event && !any_pressed_by_state) {
        const uint64_t recorded_physical_key =
            lookup_hash_table(self->mapping_records, logical_key);
        // Since this key has been pressed before, there must have been a
        // recorded physical key.
        g_return_if_fail(recorded_physical_key != 0);
        // In rare cases #recorded_logical_key is different from #logical_key.
        const uint64_t recorded_logical_key =
            lookup_hash_table(self->pressing_records, recorded_physical_key);
        synthesize_simple_event(self, kFlutterKeyEventTypeUp,
                                recorded_physical_key, recorded_logical_key,
                                timestamp);
        update_pressing_state(self, recorded_physical_key, 0);
      }
    }
    // If the modifier should be pressed, synthesize a down event for its
    // primary key.
    if (any_pressed_by_state && !any_pressed_by_record) {
      const uint64_t logical_key = checked_key->primary_logical_key;
      const uint64_t recorded_physical_key =
          lookup_hash_table(self->mapping_records, logical_key);
      // The physical key is derived from past mapping record if possible.
      //
      // The event to be synthesized is a key down event. There might not have
      // been a mapping record, in which case the hard-coded
      // #primary_physical_key is used.
      const uint64_t physical_key = recorded_physical_key != 0
                                        ? recorded_physical_key
                                        : checked_key->primary_physical_key;
      if (recorded_physical_key == 0) {
        update_mapping_record(self, physical_key, logical_key);
      }
      synthesize_simple_event(self, kFlutterKeyEventTypeDown, physical_key,
                              logical_key, timestamp);
      update_pressing_state(self, physical_key, logical_key);
    }
  }
}

// Find the stage # by the current record, which should be the recorded stage
// before the event.
static int find_stage_by_record(bool is_down, bool is_enabled) {
  constexpr int stage_by_record_index[] = {
      0,  // is_down: 0,  is_enabled: 0
      2,  //          0               1
      3,  //          1               0
      1   //          1               1
  };
  return stage_by_record_index[(is_down << 1) + is_enabled];
}

// Find the stage # by an event for the target key, which should be inferred
// stage before the event.
static int find_stage_by_self_event(int stage_by_record,
                                    bool is_down_event,
                                    bool is_state_on,
                                    bool reverse_state_logic) {
  if (!is_state_on) {
    return reverse_state_logic ? 2 : 0;
  }
  if (is_down_event) {
    return reverse_state_logic ? 0 : 2;
  }
  return stage_by_record;
}

// Find the stage # by an event for a non-target key, which should be inferred
// stage during the event.
static int find_stage_by_others_event(int stage_by_record, bool is_state_on) {
  g_return_val_if_fail(stage_by_record >= 0 && stage_by_record < 4,
                       stage_by_record);
  if (!is_state_on) {
    return 0;
  }
  if (stage_by_record == 0) {
    return 1;
  }
  return stage_by_record;
}

// Infer the logic type of CapsLock on the current platform if applicable.
//
// In most cases, when a lock key is pressed or released, its event has the
// key's state as 0-1-1-1 for the 4 stages (as documented in
// #synchronize_lock_states) respectively.  But in very rare cases it
// produces 1-1-0-1, which we call "reversed state logic".  This is observed
// when using Chrome Remote Desktop on macOS (likely a bug).
//
// To detect whether the current platform behaves normally or reversed, this
// function is called on the first down event of CapsLock before calculating
// stages.  This function then store the inferred mode as
// self->caps_lock_state_logic_inferrence.
//
// This does not help if the same app session is used alternatively between a
// reversed platform and a normal platform.  But this is the best we can do.
static void update_caps_lock_state_logic_inferrence(
    FlKeyEmbedderResponder* self,
    bool is_down_event,
    bool enabled_by_state,
    int stage_by_record) {
  if (self->caps_lock_state_logic_inferrence !=
      STATE_LOGIC_INFERRENCE_UNDECIDED) {
    return;
  }
  if (!is_down_event) {
    return;
  }
  const int stage_by_event = find_stage_by_self_event(
      stage_by_record, is_down_event, enabled_by_state, false);
  if ((stage_by_event == 0 && stage_by_record == 2) ||
      (stage_by_event == 2 && stage_by_record == 0)) {
    self->caps_lock_state_logic_inferrence = STATE_LOGIC_INFERRENCE_REVERSED;
  } else {
    self->caps_lock_state_logic_inferrence = STATE_LOGIC_INFERRENCE_NORMAL;
  }
}

// Synchronizes the lock state of a key to its state from the event by
// synthesizing events.
//
// This function might modify #caps_lock_state_logic_inferrence.
static void synchronize_lock_states(FlKeyEmbedderResponder* self,
                                    guint state,
                                    double timestamp,
                                    bool is_down,
                                    uint64_t event_logical_key) {
  GHashTableIter iter;
  g_hash_table_iter_init(&iter, self->lock_bit_to_checked_keys);
  gpointer key, value;
  while (g_hash_table_iter_next(&iter, &key, &value)) {
    guint modifier_bit = GPOINTER_TO_UINT(key);
    FlKeyEmbedderCheckedKey* checked_key =
        reinterpret_cast<FlKeyEmbedderCheckedKey*>(value);

    const uint64_t logical_key = checked_key->primary_logical_key;
    const uint64_t recorded_physical_key =
        lookup_hash_table(self->mapping_records, logical_key);
    // The physical key is derived from past mapping record if possible.
    //
    // If the event to be synthesized is a key up event, then there must have
    // been a key down event before, which has updated the mapping record.
    // If the event to be synthesized is a key down event, then there might
    // not have been a mapping record, in which case the hard-coded
    // #primary_physical_key is used.
    const uint64_t physical_key = recorded_physical_key != 0
                                      ? recorded_physical_key
                                      : checked_key->primary_physical_key;

    // A lock mode key can be at any of a 4-stage cycle, depending on whether
    // it's pressed and enabled. The following table lists the definition of
    // each stage (TruePressed and TrueEnabled), the event of the lock key
    // between every 2 stages (SelfType and SelfState), and the event of other
    // keys at each stage (OthersState). On certain platforms SelfState uses a
    // reversed rule for certain keys (SelfState(rvsd), as documented in
    // #update_caps_lock_state_logic_inferrence).
    //
    //               #    [0]         [1]          [2]           [3]
    //     TruePressed: Released    Pressed      Released      Pressed
    //     TrueEnabled: Disabled    Enabled      Enabled       Disabled
    //        SelfType:         Down         Up           Down            Up
    //       SelfState:          0           1             1              1
    // SelfState(rvsd):          1           1             0              1
    //     OthersState:    0           1            1              1
    //
    // When the exact stage can't be derived, choose the stage that requires the
    // minimal synthesization.

    const uint64_t pressed_logical_key =
        recorded_physical_key == 0
            ? 0
            : lookup_hash_table(self->pressing_records, recorded_physical_key);

    g_return_if_fail(pressed_logical_key == 0 ||
                     pressed_logical_key == logical_key);
    const int stage_by_record = find_stage_by_record(
        pressed_logical_key != 0, (self->lock_records & modifier_bit) != 0);

    const bool enabled_by_state = (state & modifier_bit) != 0;
    const bool this_key_is_event_key = logical_key == event_logical_key;
    if (this_key_is_event_key && checked_key->is_caps_lock) {
      update_caps_lock_state_logic_inferrence(self, is_down, enabled_by_state,
                                              stage_by_record);
      g_return_if_fail(self->caps_lock_state_logic_inferrence !=
                       STATE_LOGIC_INFERRENCE_UNDECIDED);
    }
    const bool reverse_state_logic =
        checked_key->is_caps_lock && self->caps_lock_state_logic_inferrence ==
                                         STATE_LOGIC_INFERRENCE_REVERSED;
    const int stage_by_event =
        this_key_is_event_key
            ? find_stage_by_self_event(stage_by_record, is_down,
                                       enabled_by_state, reverse_state_logic)
            : find_stage_by_others_event(stage_by_record, enabled_by_state);

    // The destination stage is equal to stage_by_event but shifted cyclically
    // to be no less than stage_by_record.
    constexpr int kNumStages = 4;
    const int destination_stage = stage_by_event >= stage_by_record
                                      ? stage_by_event
                                      : stage_by_event + kNumStages;

    g_return_if_fail(stage_by_record <= destination_stage);
    for (int current_stage = stage_by_record;
         current_stage < destination_stage && current_stage < 9;
         current_stage += 1) {
      const int standard_current_stage = current_stage % kNumStages;
      const bool is_down_event =
          standard_current_stage == 0 || standard_current_stage == 2;
      if (is_down_event && recorded_physical_key == 0) {
        update_mapping_record(self, physical_key, logical_key);
      }
      FlutterKeyEventType type =
          is_down_event ? kFlutterKeyEventTypeDown : kFlutterKeyEventTypeUp;
      update_pressing_state(self, physical_key,
                            is_down_event ? logical_key : 0);
      possibly_update_lock_bit(self, logical_key, is_down_event);
      synthesize_simple_event(self, type, physical_key, logical_key, timestamp);
    }
  }
}

static uint64_t corrected_modifier_physical_key(
    GHashTable* modifier_bit_to_checked_keys,
    uint64_t physical_key_from_event,
    uint64_t logical_key) {
  // If no match is found, defaults to the physical key retrieved from the
  // event.
  uint64_t corrected_physical_key = physical_key_from_event;

  // Check if the physical key is one of the known modifier physical key.
  bool known_modifier_physical_key = false;
  GHashTableIter iter;
  g_hash_table_iter_init(&iter, modifier_bit_to_checked_keys);
  gpointer value;
  while (g_hash_table_iter_next(&iter, nullptr, &value)) {
    FlKeyEmbedderCheckedKey* checked_key =
        reinterpret_cast<FlKeyEmbedderCheckedKey*>(value);
    if (checked_key->primary_physical_key == physical_key_from_event) {
      known_modifier_physical_key = true;
    }
  }

  // If the physical key matches a known modifier key, find the modifier
  // physical key from the logical key.
  if (known_modifier_physical_key) {
    g_hash_table_iter_init(&iter, modifier_bit_to_checked_keys);
    while (g_hash_table_iter_next(&iter, nullptr, &value)) {
      FlKeyEmbedderCheckedKey* checked_key =
          reinterpret_cast<FlKeyEmbedderCheckedKey*>(value);
      if (checked_key->primary_logical_key == logical_key ||
          checked_key->secondary_logical_key == logical_key) {
        corrected_physical_key = checked_key->primary_physical_key;
      }
    }
  }

  return corrected_physical_key;
}

static void fl_key_embedder_responder_handle_event_impl(
    FlKeyEmbedderResponder* responder,
    FlKeyEvent* event,
    uint64_t specified_logical_key,
    GTask* task) {
  FlKeyEmbedderResponder* self = FL_KEY_EMBEDDER_RESPONDER(responder);

  const uint64_t logical_key = specified_logical_key != 0
                                   ? specified_logical_key
                                   : event_to_logical_key(event);
  const uint64_t physical_key_from_event = event_to_physical_key(event);
  const uint64_t physical_key = corrected_modifier_physical_key(
      self->modifier_bit_to_checked_keys, physical_key_from_event, logical_key);
  guint state = fl_key_event_get_state(event);
  const double timestamp = event_to_timestamp(event);
  const bool is_down_event = fl_key_event_get_is_press(event);

  // Update lock mode states
  synchronize_lock_states(self, state, timestamp, is_down_event, logical_key);

  // Update pressing states
  synchronize_pressed_states(self, state, timestamp);

  // Construct the real event
  const uint64_t last_logical_record =
      lookup_hash_table(self->pressing_records, physical_key);

  FlutterKeyEvent out_event;
  out_event.struct_size = sizeof(out_event);
  out_event.timestamp = timestamp;
  out_event.physical = physical_key;
  out_event.logical =
      last_logical_record != 0 ? last_logical_record : logical_key;
  out_event.character = nullptr;
  out_event.synthesized = false;

  g_autofree char* character_to_free = nullptr;
  if (is_down_event) {
    if (last_logical_record) {
      // A key has been pressed that has the exact physical key as a currently
      // pressed one. This can happen during repeated events.
      out_event.type = kFlutterKeyEventTypeRepeat;
    } else {
      out_event.type = kFlutterKeyEventTypeDown;
    }
    character_to_free = event_to_character(event);  // Might be null
    out_event.character = character_to_free;
  } else {  // is_down_event false
    if (!last_logical_record) {
      // The physical key has been released before. It might indicate a missed
      // event due to loss of focus, or multiple keyboards pressed keys with the
      // same physical key. Ignore the up event.
      gboolean* return_value = g_new0(gboolean, 1);
      *return_value = TRUE;
      g_task_return_pointer(task, return_value, g_free);
      return;
    } else {
      out_event.type = kFlutterKeyEventTypeUp;
    }
  }

  if (out_event.type != kFlutterKeyEventTypeRepeat) {
    update_pressing_state(self, physical_key, is_down_event ? logical_key : 0);
  }
  possibly_update_lock_bit(self, logical_key, is_down_event);
  if (is_down_event) {
    update_mapping_record(self, physical_key, logical_key);
  }
  self->sent_any_events = true;
  g_autoptr(FlEngine) engine = FL_ENGINE(g_weak_ref_get(&self->engine));
  if (engine != nullptr) {
    fl_engine_send_key_event(
        engine, &out_event, self->cancellable,
        [](GObject* object, GAsyncResult* result, gpointer user_data) {
          g_autoptr(GTask) task = G_TASK(user_data);

          gboolean handled;
          g_autoptr(GError) error = nullptr;
          if (!fl_engine_send_key_event_finish(FL_ENGINE(object), result,
                                               &handled, &error)) {
            if (g_error_matches(error, G_IO_ERROR, G_IO_ERROR_CANCELLED)) {
              return;
            }
            g_warning("Failed to handle key event: %s", error->message);
            handled = FALSE;
          }

          gboolean* return_value = g_new0(gboolean, 1);
          *return_value = handled;
          g_task_return_pointer(task, return_value, g_free);
        },
        g_object_ref(task));
  }
}

void fl_key_embedder_responder_handle_event(FlKeyEmbedderResponder* self,
                                            FlKeyEvent* event,
                                            uint64_t specified_logical_key,
                                            GCancellable* cancellable,
                                            GAsyncReadyCallback callback,
                                            gpointer user_data) {
  g_autoptr(GTask) task = g_task_new(self, cancellable, callback, user_data);

  self->sent_any_events = false;
  fl_key_embedder_responder_handle_event_impl(self, event,
                                              specified_logical_key, task);
  if (!self->sent_any_events) {
    g_autoptr(FlEngine) engine = FL_ENGINE(g_weak_ref_get(&self->engine));
    if (engine != nullptr) {
      fl_engine_send_key_event(engine, &kEmptyEvent, self->cancellable, nullptr,
                               nullptr);
    }
  }
}

gboolean fl_key_embedder_responder_handle_event_finish(
    FlKeyEmbedderResponder* self,
    GAsyncResult* result,
    gboolean* handled,
    GError** error) {
  g_return_val_if_fail(g_task_is_valid(result, self), FALSE);

  g_autofree gboolean* return_value =
      static_cast<gboolean*>(g_task_propagate_pointer(G_TASK(result), error));
  if (return_value == nullptr) {
    return FALSE;
  }

  *handled = *return_value;
  return TRUE;
}

void fl_key_embedder_responder_sync_modifiers_if_needed(
    FlKeyEmbedderResponder* self,
    guint state,
    double event_time) {
  g_return_if_fail(FL_IS_KEY_EMBEDDER_RESPONDER(self));
  synchronize_pressed_states(self, state,
                             event_time * kMicrosecondsPerMillisecond);
}

GHashTable* fl_key_embedder_responder_get_pressed_state(
    FlKeyEmbedderResponder* self) {
  return self->pressing_records;
}
