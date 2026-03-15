open Fundywundy

exception InvalidInput of string

let rec read_cents message =
  match LNoise.linenoise message with
  | None -> read_cents message
  | Some balance -> balance
    |> String.split_on_char ','
    |> String.concat ""
    |> float_of_string
    |> Rebalance.Cents.from_float

let get_fund name = read_cents ("Current " ^ name ^ " fund balance: $")

let rec get_mode () =
  print_endline "Action: (1) Buy or (2) Sell? Enter 1 or 2: ";
  match read_line () with
  | "1" -> Rebalance.Buy
  | "2" -> Rebalance.Sell
  | _ -> get_mode ()

let targets = Rebalance.FundMap.(empty |> add "US" 65_00L |> add "ex-US" 30_00L |> add "NZ" 5_00L)

let () =
  print_endline "--- Portfolio Rebalancer ---";
  let us = get_fund "US" in
  let ex_us = get_fund "ex-US" in
  let nz = get_fund "NZ" in
  let mode = get_mode () in
  let amount = read_cents "Amount: " in
  let portfolio = Rebalance.FundMap.(empty |> add "US" us |> add "ex-US" ex_us |> add "NZ" nz) in
  let orders = Rebalance.calculate_orders portfolio amount targets mode in
  print_endline "Orders:";
  orders |> Rebalance.FundMap.iter (fun fund amount -> print_endline (fund ^ ": " ^ Rebalance.Cents.to_string amount));
