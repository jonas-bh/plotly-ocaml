open Plotly
open Data
open Graph
open Figure
open Layout
open Axis


let scatter_ =
  figure
    [ scatter
        [ xy [| (1.0, 1.0); (2.0, 2.0); (3.0, 4.0); (4.0, 8.0); (5.0, 16.0) |];
          (* mode "lines+markers" *)
        ] ]
    [ title "Scatter lines+markers" ]


let scatter_markers =
  figure
    [ scatter
        [ xy [| (1.0, 1.0); (2.0, 2.0); (3.0, 4.0); (4.0, 8.0); (5.0, 16.0) |];
          mode "markers";
        ] ]
    [ title "Scatter markers" ]

let scatter_lines =
  figure
    [ scatter
        [ xy [| (1.0, 1.0); (2.0, 2.0); (3.0, 4.0); (4.0, 8.0); (5.0, 16.0) |];
          mode "lines";
        ] ]
    [ title "Scatter lines" ]

let scatter_multi =
  figure
    [ scatter
        [ xy [| (1.0, 1.0); (2.0, 2.0); (3.0, 4.0); (4.0, 8.0); (5.0, 16.0) |];
          name "Team A";
          (* mode "lines+markers" *)
        ];
      scatter
        [ xy [| (1.0, 2.0); (2.0, 1.0); (3.0, 3.0); (4.0, 7.0); (5.0, 11.0) |];
          mode "markers";
          name "Team B";
        ] ]
    [ title "Scatter multi" ]

let scatter_text =
  figure
    [ scatter
        [ xy [| (1.0, 1.0); (2.0, 2.0); (3.0, 4.0); (4.0, 8.0); (5.0, 16.0) |];
          text [| "A"; "B"; "C"; "D"; "E" |]
        ] ]
    [ title "Scatter with hoover texts" ]

let scatter_3d =
  figure
    [ scatter3d
        [ xyz [| (1.0, 1.0, 1.0); (2.0, 2.0, 8.0); (3.0, 4.0, 27.0); (4.0, 8.0, 64.0); (5.0, 16.0, 125.0) |];
          text [| "A"; "B"; "C"; "D"; "E" |];
        ] ]
    [ title "Scatter 3D" ]

let bar_ =
  figure
    [ bar
        [ xy [| (1.0, 1.0); (2.0, 2.0); (3.0, 4.0); (4.0, 8.0); (5.0, 16.0) |];
          text [| "A"; "B"; "C"; "D"; "E" |];
        ] ]
    [ title "Bar with hoover texts" ]

let bar_stack =
  figure
    [ bar
        [ xy [| (1.0, 1.0); (2.0, 2.0); (3.0, 4.0); (4.0, 8.0); (5.0, 16.0) |];
          text [| "A"; "B"; "C"; "D"; "E" |];
        ];
      bar
        [ xy [| (1.0, 1.0); (2.0, 2.0); (3.0, 4.0); (4.0, 8.0); (5.0, 16.0) |];
          text [| "A"; "B"; "C"; "D"; "E" |];
        ] ]
    [ title "Stacked Bar";
             barmode "stack"
           ]

let bar_stack_horizontal =
  figure
    [ bar
        [ xy [| (1.0, 1.0); (2.0, 2.0); (4.0, 3.0); (8.0, 4.0); (16.0, 5.0) |];
          text [| "A"; "B"; "C"; "D"; "E" |];
          orientation "h";
        ];
      bar
        [ xy [| (1.0, 1.0); (2.0, 2.0); (4.0, 3.0); (8.0, 4.0); (16.0, 5.0) |];
          text [| "A"; "B"; "C"; "D"; "E" |];
          orientation "h";
        ] ]
    [ title "Stacked Bar, horizontal";
      barmode "stack"
    ]

let pie_ =
  figure
    [ pie [ values [| 1.0; 2.0; 3.0 |];
            labels [| "A"; "B"; "C" |];
          ] ]
    [ title "Pie" ]

let histogram_ =
  figure
    [ histogram [ x [| 0.142; 0.823; 0.456; 0.789; 0.234; 0.567; 0.891; 0.345; 0.678; 0.912;
                      0.123; 0.456; 0.789; 0.234; 0.567; 0.891; 0.345; 0.678; 0.912; 0.234;
                      0.345; 0.456; 0.567; 0.678; 0.789; 0.891; 0.234; 0.345; 0.456; 0.567;
                      0.678; 0.789; 0.234; 0.345; 0.456; 0.567; 0.678; 0.789; 0.123; 0.234;
                      0.345; 0.456; 0.567; 0.678; 0.789; 0.234; 0.345; 0.456; 0.567; 0.678 |] ] ]
    [ title "Histogram" ]

let scatter_with_axes =
  let x_data = [| 1.0; 2.0; 3.0; 4.0; 5.0 |] in
  let y_data = [| 1.0; 4.0; 9.0; 16.0; 25.0 |] in
  figure
    [ scatter [ x x_data; y y_data; mode "lines+markers" ] ]
    [
      title "Data with Custom Axis Labels";
      xaxis [axis_title "Time (seconds)"; axis_type "linear"];
      yaxis [axis_title "Distance (meters)"; axis_range 0. 30.];
    ]

let bar_hide_legend =
  figure
    [ bar
        [ xy [| (1.0, 1.0); (2.0, 2.0); (3.0, 4.0); (4.0, 8.0); (5.0, 16.0) |];
          name "Visible in Legend";
        ];
      bar
        [ xy [| (1.0, 2.0); (2.0, 1.0); (3.0, 3.0); (4.0, 7.0); (5.0, 11.0) |];
          name "Hidden from Legend";
          Data.showlegend false;
        ] ]
    [ title "Bar: Hiding Legend for Single Trace"; ]

let figures =
  [ scatter_;
    scatter_markers;
    scatter_lines;
    scatter_multi;
    scatter_text;
    scatter_3d;
    bar_;
    bar_stack;
    bar_stack_horizontal;
    pie_;
    histogram_;
    scatter_with_axes;
    bar_hide_legend;
  ]
