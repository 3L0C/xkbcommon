open Xkbcommon

(* A cut-down version of a real keymap, for testing. *)
let test_map = {|
xkb_keymap {
xkb_keycodes "(unnamed)" {
	minimum = 8;
	maximum = 66;
	<ESC>                = 9;
	<AE01>               = 10;
	<AE02>               = 11;
	<AE03>               = 12;
	<AE04>               = 13;
        <LFSH>               = 50;
	<CAPS>               = 66;
	indicator 1 = "Caps Lock";
};

xkb_types "(unnamed)" {
	type "ONE_LEVEL" {
		modifiers= none;
		level_name[1]= "Any";
	};
	type "TWO_LEVEL" {
		modifiers= Shift;
		map[Shift]= 2;
		level_name[1]= "Base";
		level_name[2]= "Shift";
	};
};

xkb_compatibility "(unnamed)" {
	virtual_modifiers NumLock;

	interpret.useModMapMods= AnyLevel;
	interpret.repeat= False;
	interpret Shift_L+AnyOfOrNone(all) {
		action= SetMods(modifiers=Shift,clearLocks);
	};
	indicator "Caps Lock" {
		whichModState= locked;
		modifiers= Lock;
	};
};

xkb_symbols "(unnamed)" {
	name[Group1]="English (UK)";
	key <ESC>                {	[          Escape ] };
	key <AE01>               {	[               1,          exclam ] };
	key <AE02>               {	[               2,        quotedbl ] };
	key <AE03>               {	[               3,        sterling ] };
	key <AE04>               {	[               4,          dollar ] };
	key <LFSH>               {	[         Shift_L ] };
	modifier_map Shift { <LFSH> };
	modifier_map Lock { <CAPS> };
};

};

|}

let with_test_keymap ?(test_map=test_map) fn =
  let fd = Unix.openfile "testmap.data" [O_RDWR; O_CREAT; O_TRUNC] 0o600 in
  Unix.unlink "testmap.data";
  let _ : int = Unix.write fd (Bytes.of_string test_map) 0 (String.length test_map) in
  let ctx = Context.create () in
  let k = Keymap.from_fd ctx fd (String.length test_map) in
  Unix.close fd;
  fn k

let test_keysym_names () =
  Alcotest.(check string) "valid"
    "Insert"
    (Keysym.get_name (Keysym.from_name ~case_insensitive:true "insert"));
  Alcotest.(check string) "case-mismatch"
    "NoSymbol"
    (Keysym.get_name (Keysym.from_name ~case_insensitive:false "insert"));
  Alcotest.(check string) "invalid"
    "NoSymbol"
    (Keysym.get_name (Keysym.from_name ~case_insensitive:true "xyzzy"))

let test_keymap_simple () =
  let k1 = 10l in
  let kShift = 50l in
  with_test_keymap @@ fun k ->
  Alcotest.(check (option string)) "Key name" (Some "AE01") (Keymap.key_get_name k k1);
  Alcotest.(check int32) "Keycode" 10l (Keymap.key_by_name k "AE01");
  Alcotest.(check (option string)) "Invalid key name" None (Keymap.key_get_name k 99l);
  Alcotest.(check int32) "Invalid keycode" (-1l) (Keymap.key_by_name k "FOO");
  Alcotest.(check bool) "1 repeats" true (Keymap.key_repeats k k1);
  Alcotest.(check bool) "Shift doesn't" false (Keymap.key_repeats k kShift);
  let state = State.create k in
  Alcotest.(check string) "Name shift key" "Shift_L" (Keysym.get_name (State.key_get_one_sym state kShift));
  Alcotest.(check (option reject)) "Unknown mod" None (Keymap.mod_get_index k "Meta");
  let shift = Option.get (Keymap.mod_get_index k "Shift") in
  Alcotest.(check bool) "Shift not pressed" false (State.mod_is_active state shift);
  Alcotest.(check string) "Test 1 unshifted" "1" (State.key_get_utf8 state k1);
  State.update_key state 50l `Down;
  Alcotest.(check bool) "Shift is pressed" true (State.mod_is_active state shift);
  Alcotest.(check string) "Test 1 shifted" "!" (State.key_get_utf8 state k1);
  State.update_key state 50l `Up;
  Alcotest.(check bool) "Shift released" false (State.mod_is_active state shift);
  ()

let test_keymap_invalid () =
  try
    with_test_keymap ~test_map:"{ foo " @@ fun _k ->
    Alcotest.fail "Should have failed to load"
  with Failure m ->
    Alcotest.(check string) "Error detected" "xkb_keymap_new_from_string returned NULL" m

let test_keysym_case () =
  let upper = Keysym.to_upper Keysym.K_a in
  Alcotest.(check string) "a -> A" "A" (Keysym.get_name upper);
  let lower = Keysym.to_lower Keysym.K_A in
  Alcotest.(check string) "A -> a" "a" (Keysym.get_name lower);
  let unchanged = Keysym.to_upper Keysym.K_1 in
  Alcotest.(check string) "1 unchanged" "1" (Keysym.get_name unchanged)

let test_keymap_from_string () =
  let ctx = Context.create () in
  let k = Keymap.from_string ctx test_map in
  Alcotest.(check (option string)) "Key name" (Some "AE01") (Keymap.key_get_name k 10l)

let test_keymap_get_as_string () =
  with_test_keymap @@ fun k ->
  let s = Keymap.get_as_string k in
  Alcotest.(check bool) "Non-empty" true (String.length s > 0);
  let ctx = Context.create () in
  let k2 = Keymap.from_string ctx s in
  Alcotest.(check (option string)) "Roundtrip" (Some "AE01") (Keymap.key_get_name k2 10l)

let test_keymap_introspection () =
  with_test_keymap @@ fun k ->
  Alcotest.(check bool) "Has mods" true (Keymap.num_mods k > 0);
  Alcotest.(check (option string)) "Mod 0 name" (Some "Shift") (Keymap.mod_get_name k (Obj.magic 0));
  Alcotest.(check bool) "Has layouts" true (Keymap.num_layouts k > 0);
  Alcotest.(check (option string)) "Layout 0 name" (Some "English (UK)") (Keymap.layout_get_name k (Obj.magic 0));
  Alcotest.(check bool) "Has LEDs" true (Keymap.num_leds k > 0);
  Alcotest.(check (option string)) "LED 0 name" (Some "Caps Lock") (Keymap.led_get_name k (Obj.magic 0));
  let min_kc = Keymap.min_keycode k in
  let max_kc = Keymap.max_keycode k in
  Alcotest.(check bool) "min < max" true (min_kc < max_kc);
  Alcotest.(check bool) "Layouts for key" true (Keymap.num_layouts_for_key k 10l > 0);
  Alcotest.(check bool) "Levels for key" true (Keymap.num_levels_for_key k 10l (Obj.magic 0) > 0)

let test_state_introspection () =
  let k1 = 10l in
  let kShift = 50l in
  with_test_keymap @@ fun k ->
  let state = State.create k in
  Alcotest.(check bool) "Shift not active by name" false (State.mod_name_is_active state "Shift");
  State.update_key state kShift `Down;
  Alcotest.(check bool) "Shift active by name" true (State.mod_name_is_active state "Shift");
  let consumed = State.key_get_consumed_mods state k1 in
  Alcotest.(check bool) "Has consumed mods" true (consumed <> 0l);
  let layout = State.key_get_layout state k1 in
  Alcotest.(check bool) "Layout >= 0" true ((Obj.magic layout : int) >= 0);
  let level = State.key_get_level state k1 layout in
  Alcotest.(check bool) "Level >= 0" true ((Obj.magic level : int) >= 0);
  let mods = State.serialize_mods state State_component.mods_effective in
  Alcotest.(check bool) "Mods non-zero with shift" true (mods <> 0l);
  State.update_key state kShift `Up;
  Alcotest.(check bool) "Caps Lock LED off" false (State.led_name_is_active state "Caps Lock")

let () =
  Alcotest.run "xkbcommon" [
    "keysym", [
      "names", `Quick, test_keysym_names;
      "case", `Quick, test_keysym_case;
    ];
    "keymap", [
      "simple", `Quick, test_keymap_simple;
      "invalid", `Quick, test_keymap_invalid;
      "from_string", `Quick, test_keymap_from_string;
      "get_as_string", `Quick, test_keymap_get_as_string;
      "introspection", `Quick, test_keymap_introspection;
    ];
    "state", [
      "introspection", `Quick, test_state_introspection;
    ]
  ]
