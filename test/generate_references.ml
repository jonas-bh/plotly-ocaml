open Plotly
open Plotly_demo

(** Utility to get a sanitized filename from a figure's title *)
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

(** Generate reference JSON files for all demo figures *)
let generate_json_references () =
  let ref_dir = "test/references/jsoo-json" in
  
  if not (Sys.file_exists ref_dir) then
    Unix.mkdir ref_dir 0o755;
  
  Printf.printf "Generating JSON references...\n%!";
  
  List.iter (fun figure ->
    let filename = get_filename figure in
    let filename_json = filename ^ ".json" in
    let path = Filename.concat ref_dir filename_json in
    
    let json = Figure.to_json figure in
    let json_str = Ezjsonm.value_to_string ~minify:false json in
    
    let oc = open_out path in
    output_string oc json_str;
    output_char oc '\n';
    close_out oc;
    
    Printf.printf "  ✓ %s\n%!" filename_json;
  ) Demo.figures;
  
  Printf.printf "Done! Generated %d JSON reference files.\n%!" (List.length Demo.figures)

(** Generate Python figure JSON reference files *)
let generate_python_references () =
  Printf.printf "\nGenerating Python figure JSON references...\n%!";
  
  let ref_dir = "test/references/python-json" in
  if not (Sys.file_exists ref_dir) then
    Unix.mkdir ref_dir 0o755;
  
  List.iter (fun figure ->
    let filename = get_filename figure in
    let filename_json = filename ^ ".json" in
    let ref_path = Filename.concat ref_dir filename_json in
    
    try
      let py_fig = Plotly_python.Python.of_figure figure in
      let py_json = Plotly_python.Python.python_figure_to_json py_fig in
      
      let json_str = Ezjsonm.value_to_string ~minify:false py_json in
      let oc = open_out ref_path in
      output_string oc json_str;
      output_string oc "\n";
      close_out oc;
      
      Printf.printf "  ✓ %s\n%!" filename_json
    with e ->
      Printf.printf "  ✗ %s - Error: %s\n%!" filename (Printexc.to_string e)
  ) Demo.figures;
  
  Printf.printf "Done! Generated %d Python reference files.\n%!" (List.length Demo.figures)

let () =
  generate_json_references ();
  generate_python_references ()
