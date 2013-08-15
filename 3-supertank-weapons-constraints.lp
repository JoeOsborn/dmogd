% Run with `clingcon --opt-all 3-supertank-weapons-constraints.lp`.
% Constraint logic programming version of supertank.
% This replaces a lot of symbolic reasoning with mathematical constraints,
% which can be solved very quickly.
% Regular clasp has to basically produce all possible combinations of loadouts
% in order to do its work, because it doesn't know how to do things with math.
% Rather, it treats math like any other set of logical relations.
% clingcon demolishes numeric problems like this one, and it also permits
% a slightly nicer-looking encoding.

% General problem encoding.

% Hard-coded limit on number of weapons of each type.
#const weapon_type_limit=20.

% These are the properties in this game.
prop(damage;weight;cost;slots).

% Limits for number of credits, slots, etc.
#const credit_limit=100.
#const weight_limit=50.
#const slot_limit=3.

% First, assert that all our numbers will be within 0..1000.
% Clingcon features are prefaced with $.
#const domain_max=1000.
$domain(0..domain_max).

% Clingcon's $== is simply saying "The thing on the left must be equal to the
% thing on the right". $* is constraint-multiplication.
% This rule gets a body because we want to constrain Prop and WT to be
% properties and weapon types.
net(Prop,WT) $== prop(Prop,WT) $* equipped(WT) :- prop(Prop), weapon(WT).
% $sum{} is another clingcon-ism; note that we don't need to give weights
% for each thing being summed, because net(Prop,WT) already has a value
% (thanks to $==) for any given WT.
net(Prop) $== $sum{net(Prop,WT):weapon(WT)} :- prop(Prop).

% Note that num_weapons is gone, because we don't need to babysit the grounder.
% Here, we say that equipped(W) is between 0 and weapon_type_limit for every
% weapon type. This replaces the choice rule with a constraint rule, which
% will be much faster.
0 $<= equipped(W) :- weapon(W).
equipped(W) $<= weapon_type_limit :- weapon(W).

% Forbid situations where values fall out of bounds. Note how these are just
% one statement rather than two.
:- net(cost) $> credit_limit.
:- net(weight) $> weight_limit.
:- net(slots) $> slot_limit.

% Unfortunately, I'm not sure how to selectively hide or show clingcon's terms.
#hide.
#show equipped/1.
#show net/2.

% Instance.

% These get a little uglier, but not too much so.
weapon(machine_gun).  
prop(damage,machine_gun) $== 2.
prop(weight,machine_gun) $== 1.
prop(cost,machine_gun)   $== 5.
prop(slots,machine_gun)  $== 0.

weapon(rockets).
prop(damage,rockets) $== 8.
prop(weight,rockets) $== 3.
prop(cost,rockets)   $== 12.
prop(slots,rockets)  $== 0.

weapon(mega_rockets).
prop(damage,mega_rockets) $== 15.
prop(weight,mega_rockets) $== 10.
prop(cost,mega_rockets)   $== 16.
prop(slots,mega_rockets)  $== 1.

weapon(laser).
prop(damage,laser) $== 7.
prop(weight,laser) $== 4.
prop(cost,laser)   $== 9.
prop(slots,laser)  $== 0.

weapon(ultra_laser).
prop(damage,ultra_laser) $== 20.
prop(weight,ultra_laser) $== 16.
prop(cost,ultra_laser)   $== 18.
prop(slots,ultra_laser)  $== 1.

% Optimization criteria.

% Unfortunately, clingcon's optimization statements are less advanced than
% clingo's, so it is difficult to do multi-objective optimization without
% falling back on clingo's statements.

% If you can calculate your own utility function, though, do try and use
% $maximize/$minimize instead of #maximize/#minimize. It's about an order
% of magnitude faster, at least on this problem--not that 0.3 seconds vs 1.8
% seconds is that big a deal!

% Fast, single-objective, clingcon
$maximize{net(damage)}.

% Slow, multi-objective, clingo.
% Note the auxiliary opt_net predicate we need to get back into clingo's world.
% opt_net(Prop,N) :-
%   prop(Prop),
%   N = 0..domain_max,
%   net(Prop) $== N.
% #maximize[opt_net(damage,N)=N@4].
% #minimize[opt_net(slots,N)=N@3].
% #minimize[opt_net(cost,N)=N@2].
% #minimize[opt_net(weight,N)=N@1].