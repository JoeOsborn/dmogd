% clingo --opt-heu --rand-freq=0.05 --rand-prob=yes 4-pvp-alt.lp
#begin_lua
function ceil_div(A, B)
  return math.ceil(A / B)
end
#end_lua.

% Problem encoding.

% Stats.

prop(hp;damage;healing;range).

1{prop(Prop,Class,Amt):valid(Prop,Amt)}1 :-
  prop(Prop), class(Class).

:- expected_best(Prop, Cls, Amt), 
   class(Cls2), Cls2 != Cls,
   prop(Prop,Cls,ClsAmt),
   prop(Prop,Cls2,Cls2Amt),
   Amt + Cls2Amt > ClsAmt.

:- class(A;B), prop(damage,A,DAmt), prop(healing,B,HAmt), DAmt <= HAmt.

#hide.
% Combat.
#const start_range=100.
#const turn_limit=17.
turn(0..turn_limit).

turns_to_kill(Left,Right,Turns) :-
  class(Left;Right), turn(Turns),
  prop(hp,Right,RHP), prop(damage,Left,LDmg), prop(healing,Right,RHeal),
  Turns = @ceil_div(RHP,LDmg - RHeal).

turns_to_close(Left,Right,Turns) :-
  class(Left;Right), turn(Turns),
  prop(range,Left,LRange), prop(range,Right,RRange),
  LRange <= RRange,
  BothTurns = @ceil_div(start_range - RRange,10),
  LeftTurns = @ceil_div(BothTurns * 10 - LRange,5),
  Turns = BothTurns + LeftTurns.
turns_to_close(Left,Right,Turns) :-
  class(Left;Right), turn(Turns),
  prop(range,Left,LRange), prop(range,Right,RRange),
  LRange > RRange,
  Turns = @ceil_div(start_range - LRange,10).

turns_to_win(Left,Right,Turns) :-
  turn(Turns),
  turns_to_close(Left,Right,Close),
  turns_to_kill(Left,Right,Kill),
  Turns = Close + Kill.

combat(warrior,mage).
combat(warrior,healer).
combat(warrior,barbarian).
combat(barbarian,mage).
combat(barbarian,healer).
combat(mage,healer).
% {combat(Left,Right):class(Left;Right)}.
% :- combat(Left,Right), combat(Right,Left).

% Instance data.

class(warrior;mage;healer;barbarian).
valid(     hp, 30..200).
valid( damage,  1.. 20).
valid(healing,  0.. 15).
valid(  range,  0..100).

expected_best(damage,warrior,4).
expected_best(range,mage,10).
expected_best(healing,healer,4).
expected_best(hp,barbarian,5).

score(Left,Right,Score) :-
  combat(Left,Right),
  turns_to_win(Left,Right,LTurns),
  turns_to_win(Right,Left,RTurns),
  turn(LTurns;RTurns),
  Score = turn_limit - | LTurns - RTurns |.

min_score(Min) :-
  combat(L1,R1),
  score(L1,R1,Min),
  0{score(L2,R2,S2):combat(L2,R2):S2>Min}0.

net_score(Sc) :-
  Sum = #sum[score(Left,Right,Score)=Score:combat(Left,Right)],
  min_score(Min),
  Sc = Sum * Min.

#maximize[net_score(Sc)=Sc].

max_score(6 * turn_limit * turn_limit).

#hide.
#show turns_to_win/3.
#show score/3.
#show net_score/1.
#show max_score/1.
#show prop/3.
