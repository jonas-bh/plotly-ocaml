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
      sanitized ^ ".json"
  | None -> failwith "Figure must have a title for regression testing"

(** Generate reference JSON files for all demo figures *)
let generate_json_references () =
  let ref_dir = "test/references/json" in
  
  if not (Sys.file_exists ref_dir) then
    Unix.mkdir ref_dir 0o755;
  
  Printf.printf "Generating JSON references...\n%!";
  
  List.iter (fun figure ->
    let filename = get_filename figure in
    let path = Filename.concat ref_dir filename in
    
    let json = Figure.to_json figure in
    let json_str = Ezjsonm.value_to_string ~minify:false json in
    
    let oc = open_out path in
    output_string oc json_str;
    output_char oc '\n';
    close_out oc;
    
    Printf.printf "  ✓ %s\n%!" filename;
  ) Demo.figures;
  
  Printf.printf "Done! Generated %d reference files.\n%!" (List.length Demo.figures)

(** Generate reference images using Python backend *)
let generate_image_references () =
  Printf.printf "\nGenerating image references (requires Python backend)...\n%!";
  
  let ref_dir = "test/references/images" in
  
  if not (Sys.file_exists ref_dir) then
    Unix.mkdir ref_dir 0o755;
  
  try
    let module Python = Plotly_python.Python in
    
    List.iter (fun figure ->
      let filename = get_filename figure in
      let png_filename = (Filename.chop_extension filename) ^ ".png" in
      let path = Filename.concat ref_dir png_filename in
      
      let py_fig = Python.of_figure figure in
      Python.write_image py_fig path;
      
      Printf.printf "  ✓ %s\n%!" png_filename;
    ) Demo.figures;
    
    Printf.printf "Done! Generated %d image references.\n%!" (List.length Demo.figures)
  with e ->
    Printf.eprintf "Error generating images: %s\n" (Printexc.to_string e);
    Printf.eprintf "Make sure Python backend is available (pyml installed).\n%!"

let () =
  generate_json_references ();
  generate_image_references ()
