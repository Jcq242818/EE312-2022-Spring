input = ones(8,1);
scr_initial = [1;1;1;1;1;1;1];
scrambled = wlanScramble(input,scr_initial);
descrambled = wlanScramble(scrambled,scr_initial);
scrambled
descrambled

