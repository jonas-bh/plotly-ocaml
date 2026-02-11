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
    let p1 = "test/references/jsoo-json/" ^ filename ^ ".json" in
    let p2 = "references/jsoo-json/" ^ filename ^ ".json" in
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

let test_python_backend figure =
  let module Python = Plotly_python.Python in
  let filename = get_filename figure in
  let ref_path = 
    let p1 = "test/references/python-json/" ^ filename ^ ".json" in
    let p2 = "references/python-json/" ^ filename ^ ".json" in
    if Sys.file_exists p1 then p1
    else if Sys.file_exists p2 then p2
    else p1
  in
  
  try
    (* Convert figure to Python object *)
    let py_fig = Python.of_figure figure in
    
    (* Extract JSON from the actual Python figure object *)
    let py_json = Python.python_figure_to_json py_fig in
    
    (* Verify it matches the Python-specific reference *)
    if Sys.file_exists ref_path then begin
      let ref_json = Ezjsonm.value_from_channel (open_in ref_path) in
      
      if not (json_equal py_json ref_json) then begin
        Printf.printf "  ✗ %s - Python figure JSON doesn't match reference\n" filename;
        false
      end else begin
        Printf.printf "  ✓ %s (Python backend)\n" filename;
        true
      end
    end else begin
      Printf.printf "  ? %s - No Python reference (run: dune exec test/generate_python_references.exe)\n" filename;
      false
    end
  with e ->
    Printf.printf "  ✗ %s - Python backend error: %s\n" filename (Printexc.to_string e);
    false


(** Run all tests *)
let run_tests () =
  Printf.printf "\n========================================\n";
  Printf.printf "PLOTLY-OCAML REGRESSION TEST SUITE\n";
  Printf.printf "========================================\n\n";
  
  Printf.printf "JSON Tests (JSOO/Plotly.js):\n";
  let json_results = List.map test_json_figure Demo.figures in
  
  Printf.printf "\nPython Backend Tests:\n";
  let python_results = 
    try
      List.map test_python_backend Demo.figures
    with e ->
      Printf.printf "  ! Python backend unavailable: %s\n" (Printexc.to_string e);
      List.map (fun _ -> false) Demo.figures
  in
  
  let json_passed = List.filter (fun x -> x) json_results |> List.length in
  let python_passed = List.filter (fun x -> x) python_results |> List.length in
  let total = List.length Demo.figures in
  
  Printf.printf "\n========================================\n";
  Printf.printf "RESULTS\n";
  Printf.printf "========================================\n";
  Printf.printf "JSON Tests:    %d/%d passed\n" json_passed total;
  Printf.printf "Python Tests:  %d/%d passed\n" python_passed total;
  
  if json_passed = total && python_passed = total then begin
    Printf.printf "\n✓ All tests passed!\n";
    exit 0
  end else begin
    Printf.printf "\n✗ Some tests failed.\n";
    exit 1
  end

let () = run_tests ()

