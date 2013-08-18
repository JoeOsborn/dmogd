#const domain_max=200.
$domain(0..domain_max).

% Problem encoding.

% Stats.

prop(hp;damage;healing;range).

prop_min(Prop) $<= prop(Prop,Class) :- class(Class),prop(Prop).
prop(Prop,Class) $<= prop_max(Prop) :- class(Class),prop(Prop).

:- class(Cls;Cls2), prop(damage,Cls) $<= prop(healing,Cls2).

:- expected_best(Prop, Cls, Amt), 
   class(Cls2), Cls2 != Cls,
   prop(Prop,Cls2) $+ Amt $> prop(Prop,Cls).

% Combat.
% 
#const start_range=100.

dps(Left,Right) $== prop(damage,Left) - prop(healing,Right) :-
  class(Left;Right).

turns_to_kill(Left,Right) $== 
  prop(hp,Right) / dps(Left,Right) :-
  class(Left;Right).

both_moving_turns(Left,Right) $== (start_range - prop(range,Right)) $/ 10 :-
  class(Left;Right).
left_moving_turns(Left,Right) $== ((both_moving_turns(Left,Right) $* 10 - prop(range,Left)) $/ 5) :-
  class(Left;Right).

turns_to_close(Left,Right) $== both_moving_turns(Left,Right) $+ left_moving_turns(Left,Right) :-
  class(Left;Right),
  prop(range,Left) $<= prop(range,Right).
turns_to_close(Left,Right) $== both_moving_turns(Left,Right) :-
  class(Left;Right),
  prop(range,Left) $> prop(range,Right).

combat_turns(Left,Right) $== $min{
  turns_to_close(Left,Right) $+ turns_to_kill(Left,Right),
  turns_to_close(Right,Left) $+ turns_to_kill(Right,Left)
} :- 
  class(Left;Right).

attack_turns(Left,Right) $== 
  (combat_turns(Left,Right) $- turns_to_close(Left,Right)) :-
  class(Left;Right).

remaining_hp(Left,Right) $== $max{
  prop(hp,Left) $- attack_turns(Left,Right) $* (prop(damage,Right) $- prop(healing,Left)),
  prop(hp,Right) $- attack_turns(Right,Left) $* (prop(damage,Left) $- prop(healing,Right))
} :-
  combat(Left,Right).

score(Left,Right) $== 
  combat_turns(Left,Right) $/ (1 $+ remaining_hp(Left,Right)) :-
  combat(Left,Right).

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
prop_min(hp)      $== 30.      prop_max(hp) $== 200.
prop_min(damage)  $==  1.  prop_max(damage) $==  20.
prop_min(healing) $==  0. prop_max(healing) $==  15.
prop_min(range)   $==  0.   prop_max(range) $== 100.

expected_best(damage,warrior,4).
expected_best(range,mage,10).
expected_best(healing,healer,4).
expected_best(hp,barbarian,5).

net_score $== $sum{
    score(Left,Right):combat(Left,Right)
  } $* $min{
    score(Left,Right):combat(Left,Right)
  }.

$maximize[net_score].

#hide.