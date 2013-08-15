% Run with `clingo --opt-all 2-supertank.lp`.
% This problem is more of a numeric constraint problem, so clasp is relatively
% slow--it finds the optimal solution in about 90 seconds if you can only carry
% up to 10 weapons of a single type, and way longer (I gave up after 15
% minutes) if you permit up to 20.
% See 2-supertank-constraints.lp for a version using the clingcon extensions
% to clasp, which can handle it in under half a second.

% General problem encoding.

% `weapon_type_limit` is a hard-coded limit on number of weapons of each 
% type. This is because we need some kind of upper bound, and the lower we 
% can put this the faster solving will be, at the expense of completeness.
#const weapon_type_limit=10.

% In this encoding of Supertank, we get a little fancy. Each weapon has a
% variety of properties (taken from the list defined by prop/1).
% To say a weapon costs 20, you can say `has(cost,WeaponType,20)`.
% We do this instead of having separate cost/2, weight/2, etc because
% this way we can write one pair of "net Whatever" predicates to get the
% total amount of any particular property. 
% This is more straightforward than a metaprogramming approach, which is
% what you would probably find in the wild.

% These are the properties in this game.
prop(damage;weight;cost;slots).

% Limits for number of credits, slots, etc.
#const credit_limit=100.
#const weight_limit=50.
#const slot_limit=3.

% The net "Prop" of a particular weapon type WT is the number of that weapon
% that the player has equipped times the value of that property for a single
% weapon.
net(Prop,WT,Net) :- 
  prop(Prop), weapon(WT),
  num_weapons(N),
  equipped(WT,N),
  has(Prop,WT,Per),
  Net = N * Per.

% The net "Prop" of an entire Supertank is the sum of the nets for each
% weapon type.
net(Prop,Net) :- 
  prop(Prop),
  Net=#sum[net(Prop,WT,N)=N:weapon(WT)].

% num_weapons/1 duplicates some information, but using it gives a hint
% to the solver about the range of specific variables.
num_weapons(0..weapon_type_limit).

% For every weapon type, some number 0<=N<=weapon_type_limit is equipped.
1{equipped(W,N):num_weapons(N)}1 :- weapon(W).

% Throw out solutions whose net cost, weight, or slot usage is too high.
:- net(cost,C), C > credit_limit.
:- net(weight,W), W > weight_limit.
:- net(slots,S), S > slot_limit.

% Hide all but the most interesting facts.
#hide.
#show equipped/2.
#show net/2.

% Instance.

% Weapon definitions.

weapon(machine_gun).
has(damage, machine_gun, 2).
has(weight, machine_gun, 1).
has(cost, machine_gun, 5).
has(slots, machine_gun, 0).

weapon(rockets).
has(damage, rockets, 8).
has(weight, rockets, 3).
has(cost, rockets, 12).
has(slots, rockets, 0).

weapon(mega_rockets).
has(damage, mega_rockets, 15).
has(weight, mega_rockets, 10).
has(cost, mega_rockets, 16).
has(slots, mega_rockets, 1).

weapon(laser).
has(damage, laser, 7).
has(weight, laser, 4).
has(cost, laser, 9).
has(slots, laser, 0).

weapon(ultra_laser).
has(damage, ultra_laser, 20).
has(weight, ultra_laser, 16).
has(cost, ultra_laser, 18).
has(slots, ultra_laser, 1).

% Optimization criteria.

% With highest priority, maximize net damage.
#maximize[net(damage,D)=D@4].
% Then try to minimize slot usage, cost, and weight in that order.
% #minimize[ net(slots,S)=S@3].
% #minimize[  net(cost,C)=C@2].
% #minimize[net(weight,W)=W@1].