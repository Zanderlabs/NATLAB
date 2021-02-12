function x = is_discrete(x)
x = iscell(x) && ( length(x) == 3 || length(x) == 4 ) && strcmp(x{1},'disc');
