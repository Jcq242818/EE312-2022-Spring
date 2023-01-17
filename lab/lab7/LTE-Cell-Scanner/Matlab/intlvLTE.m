function alpha = intlvLTE(K)
a([40
48
56
64
72
80
88
96
104
112
120
128
136
144
152
160
168
176
184
192
200
208
216
224
232
240
248
256
264
272
280
288
296
304
312
320
328
336
344
352
360
368
376
384
392
400
408
416
424
432
440
448
456
464
472
480
488
496
504
512
528
544
560
576
592
608
624
640
656
672
688
704
720
736
752
768
784
800
816
832
848
864
880
896
912
928
944
960
976
992
1008
1024
1056
1088
1120
1152
1184
1216
1248
1280
1312
1344
1376
1408
1440
1472
1504
1536
1568
1600
1632
1664
1696
1728
1760
1792
1824
1856
1888
1920
1952
1984
2016
2048
2112
2176
2240
2304
2368
2432
2496
2560
2624
2688
2752
2816
2880
2944
3008
3072
3136
3200
3264
3328
3392
3456
3520
3584
3648
3712
3776
3840
3904
3968
4032
4096
4160
4224
4288
4352
4416
4480
4544
4608
4672
4736
4800
4864
4928
4992
5056
5120
5184
5248
5312
5376
5440
5504
5568
5632
5696
5760
5824
5888
5952
6016
6080
6144
]) = 1:188;
Kidx = a(K);
b=[3	10
7	12
19	42
7	16
7	18
11	20
5	22
11	24
7	26
41	84
103	90
15	32
9	34
17	108
9	38
21	120
101	84
21	44
57	46
23	48
13	50
27	52
11	36
27	56
85	58
29	60
33	62
15	32
17	198
33	68
103	210
19	36
19	74
37	76
19	78
21	120
21	82
115	84
193	86
21	44
133	90
81	46
45	94
23	48
243	98
151	40
155	102
25	52
51	106
47	72
91	110
29	168
29	114
247	58
29	118
89	180
91	122
157	62
55	84
31	64
17	66
35	68
227	420
65	96
19	74
37	76
41	234
39	80
185	82
43	252
21	86
155	44
79	120
139	92
23	94
217	48
25	98
17	80
127	102
25	52
239	106
17	48
137	110
215	112
29	114
15	58
147	118
29	60
59	122
65	124
55	84
31	64
17	66
171	204
67	140
35	72
19	74
39	76
19	78
199	240
21	82
211	252
21	86
43	88
149	60
45	92
49	846
71	48
13	28
17	80
25	102
183	104
55	954
127	96
27	110
29	112
29	114
57	116
45	354
31	120
59	610
185	124
113	420
31	64
17	66
171	136
209	420
253	216
367	444
265	456
181	468
39	80
27	164
127	504
143	172
43	88
29	300
45	92
157	188
47	96
13	28
111	240
443	204
51	104
51	212
451	192
257	220
57	336
313	228
271	232
179	236
331	120
363	244
375	248
127	168
31	64
33	130
43	264
33	134
477	408
35	138
233	280
357	142
337	480
37	146
71	444
71	120
37	152
39	462
127	234
39	158
39	80
31	96
113	902
41	166
251	336
43	170
21	86
43	174
45	176
45	178
161	120
89	182
323	184
47	186
23	94
47	190
263	480
];
f1 = b(Kidx,1);
f2 = b(Kidx,2);

alpha = mod( (f1.*(0:(K-1)) + f2.*(0:(K-1)).*(0:(K-1))), K);

alpha = alpha + 1;
