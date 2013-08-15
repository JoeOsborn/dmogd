% Example taken from Decision Modeling and Optimization in Game Design, Part 5.
% http://intelligenceengine.blogspot.com/2013/08/decision-modeling-and-optimization-in.html
% To run (assuming this text is a file on your computer somewhere!):
% 1. First, download clingo (http://sourceforge.net/projects/potassco/files/clingo/3.0.5/).
% 2. Next, put clingo in your PATH somewhere and...
% 3. clingo -n 0 5-class-assignment.lp
% You should get a list of has_spell and has_perk facts representing the 
%  (only possible) assignment!
% The -n 0 means "emit all of the possible models", rather than the default of
%  1 model; in this particular case, there's only one model anyway.

% Domain encoding.

% Spells and perks are assigned to classes arbitrarily.
% The curly braces mean "some number of these statements", and since this is 
%  a fact (no right-hand-side; you'll see what that means later), the statement
%  must be true. So, "some number of these statements must be true".
% The colons are a shorthand which says e.g.:
%  "Produce all combinations of has_spell(Class,Spell) 
%   for every class and spell."
% Capitalized words (or those beginning with underscore) are variables.
% Taken together, this effectively tries out every possible assignment
%  (even undesirable ones) of classes to spells (respectively perks).
{has_spell(Class,Spell):class(Class):spell(Spell)}.
{has_perk(Class,Perk):class(Class):perk(Perk)}.

% Since we have undesirable assignments (for flexibility and simplicity),
%  now we need to knock them out of the running with constraints.

% If any class does not have exactly one spell/perk, fail.
% Read: "Fail when there is some class Class which has a 
%        number of spells lesser or greater than 1."
% The :- separates the left and right hand sides of a rule. If there is
% no left hand side, the statement must be false.
% Now our curly braces appear on the right-hand side, so they're a condition 
%  rather than a statement. They also have a 1 on the left and a 1 on the
%  right; this is a "count" condition. The left hand number indicates a minimum
%  (default 0) and the right hand side indicates a maximum (default infinity).
% The underscore by itself is a "don't-care" variable.
% These constraints remove all assignments in which classes
%  get multiple (or zero) spells (respectively perks).
:- class(Class), not 1{has_spell(Class, _)}1.
:- class(Class), not 1{has_perk(Class, _)}1.

% If any spell or perk is not held by exactly one class, fail.
% This works analogously to the constraints on lines 31-32.
% So, these four constraints combine to say:
%  "Every class has exactly one perk and spell, and every perk
%   and spell are on exactly one class."
:- spell(Spell), not 1{has_spell(Class, Spell)}1.
:- perk(Perk), not 1{has_perk(Class, Perk)}1.

% Hide everything in the output except for has_perk and has_spell.
% This is just for cosmetic purposes.
#hide.
#show has_perk/2.
#show has_spell/2.

% Problem instance.

% Declare classes, spells, and perks.
% Semicolons just mean e.g. "class(warlock). class(wizard). class(mage)..."
class(warlock;wizard;mage;runecaster;sorcelator).
spell(fireball;iceball;spell_steal;drain_life;smashing_hand).
perk(mana_regeneration;endurance;haste;fire_mastery;ice_mastery).

% The statements here could lead to multiple perks/spells for a given class
% but the four constraints in the problem encoding fix that.

% If someone has Ice/Fire Mastery, they get the respective Ball spell.
% This could also be written the other way around, or written both ways at once.
% The constraints take care of any inconsistencies that might arise.
% This is our first rule with both a left and a right hand side. If the right
% side is true, then the left side must also be true.
has_spell(Class, iceball) :- has_perk(Class, ice_mastery).
has_spell(Class, fireball) :- has_perk(Class, fire_mastery).

% Warlocks get Mana Regeneration.
has_perk(warlock, mana_regeneration).

% Wizards don't get Iceball. 
% The minus sign means "it is logically false that."
% You can imagine that there's always an implicit constraint that says:
%  "Reject any answer where a literal L is true and a literal -L is also true."
-has_spell(wizard, iceball).

% Runecasters get Drain Life.
has_spell(runecaster, drain_life).

% Mages don't get Haste.
-has_perk(mage, haste).

% The class with Spell Steal does not get Mana Regeneration.
-has_perk(Class, mana_regeneration) :- has_spell(Class, spell_steal).

% Mages don't get Ball spells.
-has_spell(mage, fireball;iceball).