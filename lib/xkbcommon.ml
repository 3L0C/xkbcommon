module Keycode = struct
  type t = int32
end

module Keysym = struct
  include Keysyms

  (* Keysyms are 32-bit integers with the 3 most significant bits always set to zero. *)
  external raw_get_name : int -> string = "caml_xkb_keysym_get_name"
  external raw_from_name : string -> bool -> int = "caml_xkb_keysym_from_name"
  external raw_to_upper : int -> int = "caml_xkb_keysym_to_upper"
  external raw_to_lower : int -> int = "caml_xkb_keysym_to_lower"

  let from_name ~case_insensitive x = of_int (raw_from_name x case_insensitive)
  let get_name t = raw_get_name (to_int t)
  let to_upper t = of_int (raw_to_upper (to_int t))
  let to_lower t = of_int (raw_to_lower (to_int t))
end

module Context = struct
  type t

  external create : unit -> t = "caml_xkb_context_new"
end

module Mod = struct
  type t = private int
end

module Led = struct
  type t = private int
end

module Layout = struct
  type t = private int
end

module Level = struct
  type t = private int
end

module Keymap = struct
  type t

  external from_fd : Context.t -> Unix.file_descr -> int -> t = "caml_xkb_keymap_from_fd"
  external from_string : Context.t -> string -> t = "caml_xkb_keymap_new_from_string"
  external get_as_string : t -> string = "caml_xkb_keymap_get_as_string"
  external key_repeats : t -> Keycode.t -> bool = "caml_xkb_keymap_key_repeats"
  external key_get_name : t -> Keycode.t -> string option = "caml_xkb_keymap_key_get_name"
  external key_by_name : t -> string -> Keycode.t = "caml_xkb_keymap_key_by_name"
  external min_keycode : t -> Keycode.t = "caml_xkb_keymap_min_keycode"
  external max_keycode : t -> Keycode.t = "caml_xkb_keymap_max_keycode"
  external num_mods : t -> int = "caml_xkb_keymap_num_mods"
  external mod_get_name : t -> Mod.t -> string option = "caml_xkb_keymap_mod_get_name"
  external mod_get_index : t -> string -> Mod.t option = "caml_xkb_keymap_mod_get_index"
  external num_layouts : t -> int = "caml_xkb_keymap_num_layouts"
  external layout_get_name : t -> Layout.t -> string option = "caml_xkb_keymap_layout_get_name"
  external layout_get_index : t -> string -> Layout.t option = "caml_xkb_keymap_layout_get_index"
  external num_leds : t -> int = "caml_xkb_keymap_num_leds"
  external led_get_name : t -> Led.t -> string option = "caml_xkb_keymap_led_get_name"
  external led_get_index : t -> string -> Led.t option = "caml_xkb_keymap_led_get_index"
  external num_layouts_for_key : t -> Keycode.t -> int = "caml_xkb_keymap_num_layouts_for_key"
  external num_levels_for_key : t -> Keycode.t -> Layout.t -> int = "caml_xkb_keymap_num_levels_for_key"
end

module State_component = struct
  type t = int
  let mods_depressed = 1
  let mods_latched = 2
  let mods_locked = 4
  let mods_effective = 8
  let layout_depressed = 16
  let layout_latched = 32
  let layout_locked = 64
  let layout_effective = 128
  let leds = 256

  let ( lor ) = ( lor )
end

module State = struct
  type t

  external create : Keymap.t -> t = "caml_xkb_state_new"
  external raw_key_get_one_sym : t -> Keycode.t -> int = "caml_xkb_state_key_get_one_sym"
  external key_get_utf8 : t -> Keycode.t -> string = "caml_xkb_state_key_get_utf8"
  external update_mask : t -> int32 -> int32 -> int32 -> int32 -> unit = "caml_xkb_state_update_mask"
  external update_key : t -> Keycode.t -> bool -> unit = "caml_xkb_state_update_key"
  external update_latched_locked : t -> int32 -> int32 -> bool -> int32 -> int32 -> int32 -> bool -> int32 -> unit = "caml_xkb_state_update_latched_locked_bytecode" "caml_xkb_state_update_latched_locked"
  external mod_is_active : t -> Mod.t -> bool = "caml_xkb_state_mod_index_is_active"
  external mod_name_is_active : t -> string -> bool = "caml_xkb_state_mod_name_is_active"
  external key_get_layout : t -> Keycode.t -> Layout.t = "caml_xkb_state_key_get_layout"
  external key_get_level : t -> Keycode.t -> Layout.t -> Level.t = "caml_xkb_state_key_get_level"
  external serialize_mods : t -> State_component.t -> int32 = "caml_xkb_state_serialize_mods"
  external serialize_layout : t -> State_component.t -> Layout.t = "caml_xkb_state_serialize_layout"
  external key_get_consumed_mods : t -> Keycode.t -> int32 = "caml_xkb_state_key_get_consumed_mods"
  external led_name_is_active : t -> string -> bool = "caml_xkb_state_led_name_is_active"
  external led_index_is_active : t -> Led.t -> bool = "caml_xkb_state_led_index_is_active"

  let key_get_one_sym t k = Keysym.of_int (raw_key_get_one_sym t k)

  let update_mask t ~mods_depressed ~mods_latched ~mods_locked ~group =
    update_mask t mods_depressed mods_latched mods_locked group

  let update_key t k dir =
    update_key t k (match dir with `Up -> false | `Down -> true)

  let update_latched_locked t ~affect_latched_mods ~latched_mods ~affect_latched_layout ~latched_layout ~affect_locked_mods ~locked_mods ~affect_locked_layout ~locked_layout =
    update_latched_locked t affect_latched_mods latched_mods affect_latched_layout latched_layout affect_locked_mods locked_mods affect_locked_layout locked_layout
end
