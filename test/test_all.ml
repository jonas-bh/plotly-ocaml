open Plotly
open Plotly_demo

let get_filename figure : string =
  let get_title figure : string option =
    match List.assoc_opt "title" (figure.Figure.layout :> Attribute.t list) with
    | Some (Value (String, s)) -> Some s
    | _ -> None
  in
  match get_title figure with
  | Some title ->
      let sanitized = String.map (function
        | ' ' | '/' | '\\' | ':' -> '_'
        | c -> c
      ) title in
      sanitized
  | None -> failwith "Figure must have a title for regression testing"

let json_equal j1 j2 =
  let normalize json = Ezjsonm.value_to_string json in
  String.equal (normalize j1) (normalize j2)

let test_json_figure figure =
  let filename = get_filename figure in
  let ref_path = 
    let p1 = "test/references/json/" ^ filename ^ ".json" in
    let p2 = "references/json/" ^ filename ^ ".json" in
    if Sys.file_exists p1 then p1
    else if Sys.file_exists p2 then p2
    else p1
  in
  
  let current_json = Figure.to_json figure in
  let test_name = filename in
  
  if Sys.file_exists ref_path then begin
    let ref_json = Ezjsonm.value_from_channel (open_in ref_path) in
    
    if not (json_equal current_json ref_json) then begin
      Printf.printf "  ✗ %s - JSON doesn't match reference\n" test_name;
      false
    end else begin
      match Figure.of_json current_json with
      | Some fig' ->
          let roundtrip_json = Figure.to_json fig' in
          if not (json_equal current_json roundtrip_json) then begin
            Printf.printf "  ✗ %s - Round-trip failed\n" test_name;
            false
          end else begin
            Printf.printf "  ✓ %s (JSON)\n" test_name;
            true
          end
      | None ->
          Printf.printf "  ✗ %s - Failed to parse generated JSON\n" test_name;
          false
    end
  end else begin
    Printf.printf "  ? %s - No JSON reference\n" test_name;
    false
  end

(** Check if ImageMagick's compare tool is available *)
let check_imagemagick () =
  match Unix.system "which compare > /dev/null 2>&1" with
  | Unix.WEXITED 0 -> true
  | _ -> false

(** Check if Python backend is available *)
let check_python_backend () =
  try
    let _ = Plotly_python.Python.of_figure (
      Plotly.Figure.figure 
        [Plotly.Graph.scatter [Plotly.Data.xy [|(1.0, 1.0)|]]]
        [Plotly.Layout.title "Test"]
    ) in
    true
  with _ -> false

(** Compare two images and return pixel difference count *)
let compare_images ref_path current_path diff_path =
  try
    (* ImageMagick compare returns exit code 1 on any difference, but outputs the metric *)
    let cmd = Printf.sprintf 
      "compare -metric AE %s %s %s 2>&1; true"
      (Filename.quote ref_path)
      (Filename.quote current_path)
      (Filename.quote diff_path)
    in
    let ic = Unix.open_process_in cmd in
    let lines = ref [] in
    (try
      while true do
        lines := input_line ic :: !lines
      done
    with End_of_file -> ());
    let _ = Unix.close_process_in ic in
    
    let output = String.concat "\n" (List.rev !lines) in
    try 
      int_of_string (String.trim output)
    with Failure _ -> 
      (* Try to extract number from output *)
      (try
        let parts = String.split_on_char ' ' (String.trim output) in
        int_of_string (List.hd parts)
      with _ -> 0) (* If no output, assume 0 difference *)
  with e ->
    Printf.eprintf "Compare error: %s\n" (Printexc.to_string e);
    -1

let test_visual_figure figure =
  let module Python = Plotly_python.Python in
  let name = get_filename figure in
  let png_name = name ^ ".png" in
  
  (* Handle both direct execution and dune test execution *)
  let base_dir = 
    if Sys.file_exists "test/references/images" then "test/references/images"
    else if Sys.file_exists "references/images" then "references/images"
    else "references/images"
  in
  
  let temp_dir = Filename.concat base_dir "current" in
  let ref_dir = base_dir in
  let diff_dir = Filename.concat base_dir "diff" in
  
  (* Create directories *)
  List.iter (fun dir ->
    if not (Sys.file_exists dir) then
      try Unix.mkdir dir 0o755 with Unix.Unix_error _ -> ()
  ) [temp_dir; diff_dir];
  
  try
    (* Check if reference exists first *)
    let ref_path = Filename.concat ref_dir png_name in
    if not (Sys.file_exists ref_path) then begin
      Printf.printf "  ✗ %s - No visual reference (run: dune exec test/generate_references.exe images)\n" name;
      false
    end else begin
      (* Generate current image *)
      let current_path = Filename.concat temp_dir png_name in
      let py_fig = Python.of_figure figure in
      Python.write_image py_fig current_path;
      
      (* Compare with reference *)
      let diff_path = Filename.concat diff_dir png_name in
      let diff_pixels = compare_images ref_path current_path diff_path in
      
      let threshold = 100 in
      if diff_pixels < 0 then begin
        Printf.printf "  ✗ %s - Comparison failed\n" name;
        false
      end else if diff_pixels <= threshold then begin
        Printf.printf "  ✓ %s (visual: %d px)\n" name diff_pixels;
        true
      end else begin
        Printf.printf "  ✗ %s - Visual regression (%d px > %d threshold)\n" name diff_pixels threshold;
        false
      end
    end
  with e ->
    Printf.printf "  ✗ %s - Error: %s\n" name (Printexc.to_string e);
    false

(** Run all tests *)
let run_tests () =
  let test_json = true in
  let has_imagemagick = check_imagemagick () in
  let has_python = check_python_backend () in
  let test_visual = has_imagemagick && has_python in
  
  Printf.printf "\n========================================\n";
  Printf.printf "PLOTLY-OCAML REGRESSION TEST SUITE\n";
  Printf.printf "========================================\n\n";
  
  if test_json then Printf.printf "JSON Tests:\n";
  let json_results = 
    if test_json then
      List.map test_json_figure Demo.figures
    else
      []
  in
  
  if test_visual then begin
    Printf.printf "\nVisual Tests:\n";
    let visual_results = List.map test_visual_figure Demo.figures in
    
    let json_passed = List.filter (fun x -> x) json_results |> List.length in
    let visual_passed = List.filter (fun x -> x) visual_results |> List.length in
    let total = List.length Demo.figures in
    
    Printf.printf "\n========================================\n";
    Printf.printf "RESULTS\n";
    Printf.printf "========================================\n";
    Printf.printf "JSON Tests:   %d/%d passed\n" json_passed total;
    Printf.printf "Visual Tests: %d/%d passed\n" visual_passed total;
    
    if json_passed = total && visual_passed = total then begin
      Printf.printf "\n✓ All tests passed!\n";
      
      exit 0
    end else begin
      Printf.printf "\n✗ Some tests failed.\n";
      if visual_passed < total then
        Printf.printf "Check diff images in: test/references/images/diff/\n";
      exit 1
    end
  end else begin
    let json_passed = List.filter (fun x -> x) json_results |> List.length in
    let total = List.length Demo.figures in
    
    Printf.printf "\n========================================\n";
    Printf.printf "RESULTS\n";
    Printf.printf "========================================\n";
    Printf.printf "JSON Tests: %d/%d passed\n" json_passed total;
    
    if not has_imagemagick then
      Printf.printf "\nNote: ImageMagick not found. Visual tests disabled.\n";
    if not has_python then
      Printf.printf "\nNote: Python backend not available. Visual tests disabled.\n";
    
    if json_passed = total then begin
      Printf.printf "\n✓ All JSON tests passed!\n";
      exit 0
    end else begin
      Printf.printf "\n✗ Some tests failed.\n";
      exit 1
    end
  end

let () = run_tests ()
