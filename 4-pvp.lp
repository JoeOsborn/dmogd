#begin_lua
function ceil_div(A, B)
  return math.ceil(A / B)
end
#end_lua.

% Problem encoding.

#const max_turns=200.

#const min_hp=30. #const max_hp=200.
#const min_dmg=1. #const max_dmg=30.
#const min_heal=0. #const max_heal=15.
#const min_rng=0. #const max_rng=100.

% Stats.

prop(hp;damage;healing;range).

1{prop(Prop,Class,Amt):valid(Prop,Amt)}1 :-
  prop(Prop), class(Class).

:- class(Cls;Cls2), 
   prop(healing,Cls,HAmt),
   prop(damage,Cls2,DAmt),
   DAmt <= HAmt.

:- expected_best(Prop, Cls, Amt), 
   class(Cls2), Cls2 != Cls,
   prop(Prop,Cls,ClsAmt),
   prop(Prop,Cls2,Cls2Amt),
   Amt + Cls2Amt > ClsAmt.

% Combat.

#base.
#const start_range=100.

side(left;right).
other(left,right). other(right,left).
which(left,Left,Right,Left) :- combat(Left,Right).
which(right,Left,Right,Right) :- combat(Left,Right).

distance(0,Left,Right,start_range) :- 
  combat(Left,Right).

in_range(0,Side,Left,Right) :-
  side(Side), class(Left;Right),
  distance(0,Left,Right,Dist),
  Dist = 0..start_range,
  which(Side,Left,Right,Which),
  prop(range,Which,Amt),
  Amt = min_rng..max_rng,
  Amt >= Dist.

hp(0,Side,Left,Right,HP) :-
  side(Side), combat(Left,Right), 
  which(Side,Left,Right,Which),
  prop(hp,Which,HP).

damage(0,Side,Left,Right,0) :-
  side(Side), combat(Left,Right).

attacks(0,Side,Left,Right) :- 
  side(Side), combat(Left,Right),
  in_range(0,Side,Left,Right).

alive(0,Side,Left,Right) :-
  side(Side), combat(Left,Right).

fighting(0,L,R) :- combat(L,R).

turn(1..max_turns).

distance(T,Left,Right,New) :-
  combat(Left,Right),turn(T),
  distance(T-1,Left,Right,Old),
  Old = 0..start_range,
  AttackCount = #count{attacks(T-1,Side,Left,Right):side(Side)},
  MoveCount = 2 - AttackCount,
  New = 0..start_range,
  New = Old - 5 * MoveCount.

in_range(T,Side,Left,Right) :-
  side(Side), class(Left;Right), turn(T),
  distance(T,Left,Right,Dist),
  Dist = 0..start_range,
  which(Side,Left,Right,Which),
  prop(range,Which,Amt),
  Amt = min_rng..max_rng,
  Amt >= Dist.

attacks(T,Side,Left,Right) :- 
  side(Side), combat(Left,Right), turn(T),
  fighting(T,Left,Right),
  in_range(T,Side,Left,Right).

fighting(T,L,R) :-
  combat(L,R), turn(T),
  alive(T,left,L,R), 
  alive(T,right,L,R).

hp(T,Side,Left,Right,HP) :-
  side(Side), combat(Left,Right), turn(T),
  fighting(T-1,Left,Right),
  hp(T-1,Side,Left,Right,OldHP),
  which(Side,Left,Right,Which),
  prop(healing,Which,Healing),
  other(Side,OtherSide),
  which(OtherSide,Left,Right,Other),
  prop(damage,Other,Damage),
  WasAttacked = #count{attacks(T-1,OtherSide,Left,Right)},
  HP = OldHP + Healing - WasAttacked*Damage.

alive(T,Side,Left,Right) :-
  side(Side), combat(Left,Right), turn(T),
  hp(T,Side,Left,Right,HP),
  HP > 0.

score(@ceil_div(max_turns, (1 + 0..max_hp*2))).

duration(Left,Right,Duration) :-
  combat(Left,Right),
  turn(Duration),
  Duration = #count{fighting(T,Left,Right):turn(T)}.
score(Left,Right,Score) :-
  combat(Left,Right),
  duration(Left,Right,Duration),
  turn(Duration),
  TotalHP = 0..max_hp*2,
  hp(Duration,left,Left,Right,LHP),hp(Duration,right,Left,Right,RHP),
  TotalHP = LHP+RHP,
  score(Score),
  Score = @ceil_div(Duration, (1 + TotalHP)).

% Instance data.

combat(warrior,mage).
combat(warrior,healer).
combat(warrior,barbarian).
combat(barbarian,mage).
combat(barbarian,healer).
combat(mage,healer).
% {combat(Left,Right):class(Left;Right)}.
% :- combat(Left,Right), combat(Right,Left).

class(warrior;mage;healer;barbarian).
valid(     hp,  min_hp..  max_hp).
valid( damage, min_dmg.. max_dmg).
valid(healing,min_heal..max_heal).
valid(  range, min_rng.. max_rng).

expected_best(damage,warrior,4).
expected_best(range,mage,10).
expected_best(healing,healer,4).
expected_best(hp,barbarian,5).

min_score(Score) :-
  score(L1,R1,Score),
  score(Score),
  0{score(L2,R2,Score2):combat(L2,R2):score(Score2):Score2 > Score}0.
net_score(Sc) :-
  Sum = #sum[score(Left,Right,Score)=Score:combat(Left,Right):score(Score)],
  min_score(Min),
  score(Min),
  MaxScore = @ceil_div(max_turns, (1 + max_hp*2)),
  Sc = 0..(MaxScore*6*MaxScore),
  Sc = Sum * Min.
:- 0{net_score(Sc):score(Sc)}0.
#maximize[net_score(Sc)=Sc].

#hide valid/2.
#show prop/3.
#show score/4.
#show net_score/2.