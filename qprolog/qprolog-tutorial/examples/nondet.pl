% Non-deterministic programming: a small grammar.
% Run forwards it checks a sentence; asked for all solutions
% it generates every sentence the grammar allows.
sentence --> noun_phrase, verb_phrase.
noun_phrase --> det, noun.
verb_phrase --> verb, noun_phrase.

det  --> [the].
det  --> [a].
noun --> [parser].
noun --> [sentence].
verb --> [corrects].
verb --> [reads].
