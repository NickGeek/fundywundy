module Cents = struct
  include Int64
  let (+) = add
  let (-) = sub
  let ( * ) = mul
  let (/) = div
  let from_float = fun x -> Int64.of_float (x *. 100.0)

  (** [to_string] converts a 64-bit integer representing cents to a string in the format "$X.XX". *)
  let to_string (cents : t) =
    let dollars = div cents 100L in
    let remaining = rem cents 100L |> abs in
    Printf.sprintf "$%Ld.%02Ld" dollars remaining
end

(** Basis points, so 10_000 == 100%, i.e 1 unit is 0.01% *)
module BasisPoints = struct
include Int64
  let (+) = add
  let (-) = sub
  let ( * ) = mul
  let (/) = div
  let from_float = fun x -> Int64.of_float (x *. 100.0)

  (** [percentage_of] gets this many basis points of a number, i.e. 1% of n if points is 1_00 *)
  let percentage_of (points : t) n = div (mul points n) 10_000L
end

module FundMap = struct
  include Map.Make(String)
  open Map.Make(String)
  let length map = fold (fun _ _ acc -> acc + 1) map 0

  let update_any f (map : 'a t) =
    let has_run = ref false in
    fold (fun key value acc ->
      if not (!has_run) then
        let _ = has_run := true in
        acc |> add key (f key value)
      else
        acc |> add key value
    ) map empty
end

type balances = Cents.t FundMap.t
let balances_to_string (map : balances) =
  FundMap.fold (fun fund balance acc ->
    acc ^ fund ^ ": " ^ Cents.to_string balance ^ "\n"
  ) map ""

type fund_targets = BasisPoints.t FundMap.t

let balances_total (balances : balances) : Cents.t =
  let open Cents in
  FundMap.fold (fun _fund balance acc -> acc + balance) balances 0L

type order_mode = Buy | Sell
let calculate_orders (balances : balances) amount (targets : fund_targets) mode : balances =
  assert (FundMap.length balances = FundMap.length targets);
  assert (not (FundMap.is_empty balances));
  let open Cents in
  let new_total = balances_total balances + (match mode with Buy -> amount | Sell -> amount * -1L) in

  let deltas = FundMap.mapi (fun fund balance ->
    let target_basis_points = targets |> FundMap.find fund in
    let delta = match mode with
      | Buy -> (BasisPoints.percentage_of target_basis_points new_total) - balance
      | Sell -> balance - (BasisPoints.percentage_of target_basis_points new_total) in
    max 0L delta
  ) balances in

  let total_delta = balances_total deltas in
  let orders : balances = deltas |> FundMap.map (fun delta ->
    if total_delta > 0L then
      (delta * amount) / total_delta
    else
      0L) in
  (* Distribute any left over cents to the first fund in the map *)
  let spent = balances_total orders in
  let remaining = amount - spent in
  let orders = if remaining = 0L then
    orders
  else
    orders |> FundMap.update_any (fun _ amount -> amount + remaining) in
  assert (amount = (balances_total orders));
  orders
