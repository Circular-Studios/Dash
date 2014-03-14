/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module WaveTable;

struct ENV
{
     int iTime;
     int iValue;
}

struct PRT
{
     ENV[] ampArray;
     ENV[] freqArray;
}

struct INS
{
     int   iMsecTime;
     PRT[] pprt;
}

enum envTrumAmp01 = [ENV(1, 0), ENV(20, 305), ENV(36, 338), ENV(141, 288), ENV(237, 80), ENV(360, 0)];
enum envTrumFrq01 = [ENV(1, 321), ENV(16, 324), ENV(32, 312), ENV(109, 310), ENV(317, 314), ENV(360, 310)];

enum envTrumAmp02 = [ENV(1, 0), ENV(3, 0), ENV(25, 317), ENV(39, 361), ENV(123, 295), ENV(222, 40), ENV(326, 0), ENV(360, 0)];
enum envTrumFrq02 = [ENV(1, 0), ENV(2, 0), ENV(3, 607), ENV(16, 657), ENV(24, 621), ENV(133, 621), ENV(275, 628), ENV(326, 628), ENV(327, 0), ENV(360, 0)];

enum envTrumAmp03 = [ENV(1, 0), ENV(2, 0), ENV(19, 100), ENV(34, 369), ENV(111, 342), ENV(207, 41), ENV(273, 0), ENV(360, 0)];
enum envTrumFrq03 = [ENV(1, 0), ENV(2, 977), ENV(5, 782), ENV(15, 987), ENV(24, 932), ENV(128, 932), ENV(217, 936), ENV(273, 945), ENV(275, 0), ENV(360, 0)];

enum envTrumAmp04 = [ENV(1, 0), ENV(3, 0), ENV(24, 113), ENV(29, 257), ENV(118, 231), ENV(187, 35), ENV(235, 0), ENV(360, 0)];
enum envTrumFrq04 = [ENV(1, 0), ENV(2, 0), ENV(3, 718), ENV(16, 1335), ENV(24, 1243), ENV(108, 1240), ENV(199, 1248), ENV(235, 1248), ENV(236, 0), ENV(360, 0)];

enum envTrumAmp05 = [ENV(1, 0), ENV(27, 52), ENV(34, 130), ENV(110, 126), ENV(191, 13), ENV(234, 0), ENV(360, 0)];
enum envTrumFrq05 = [ENV(1, 1225), ENV(9, 1569), ENV(12, 1269), ENV(21, 1573), ENV(37, 1553), ENV(97, 1552), ENV(181, 1556), ENV(234, 1566), ENV(235, 0), ENV(360, 0)];

enum envTrumAmp06 = [ENV(1, 0), ENV(46, 83), ENV(64, 100), ENV(100, 100), ENV(189, 11), ENV(221, 0), ENV(360, 0)];
enum envTrumFrq06 = [ENV(1, 1483), ENV(12, 1572), ENV(23, 1988), ENV(33, 1864), ENV(114, 1864), ENV(177, 1868), ENV(221, 1879), ENV(222, 0), ENV(360, 0)];

enum envTrumAmp07 = [ENV(1, 0), ENV(37, 39), ENV(45, 77), ENV(110, 79), ENV(176, 11), ENV(205, 0), ENV(207, 0), ENV(360, 0)];
enum envTrumFrq07 = [ENV(1, 1792), ENV(9, 1612), ENV(29, 2242), ENV(36, 2174), ENV(93, 2176), ENV(126, 2170), ENV(205, 2188), ENV(207, 0), ENV(360, 0)];

enum envTrumAmp08 = [ENV(1, 0), ENV(2, 0), ENV(28, 17), ENV(43, 71), ENV(109, 66), ENV(172, 8), ENV(201, 0), ENV(360, 0)];
enum envTrumFrq08 = [ENV(1, 0), ENV(2, 1590), ENV(29, 2539), ENV(36, 2491), ENV(114, 2481), ENV(153, 2489), ENV(201, 2491), ENV(203, 0), ENV(360, 0)];

enum envTrumAmp09 = [ENV(1, 0), ENV(2, 0), ENV(29, 16), ENV(43, 53), ENV(54, 66), ENV(105, 64), ENV(165, 7), ENV(191, 0), ENV(360, 0)];
enum envTrumFrq09 = [ENV(1, 0), ENV(2, 1993), ENV(25, 2121), ENV(32, 2821), ENV(37, 2796), ENV(84, 2798), ENV(105, 2792), ENV(191, 2797), ENV(192, 0), ENV(360, 0)];

enum envTrumAmp10 = [ENV(1, 0), ENV(27, 6), ENV(41, 25), ENV(56, 29), ENV(72, 22), ENV(95, 24), ENV(180, 0), ENV(360, 0)];
enum envTrumFrq10 = [ENV(1, 1792), ENV(12, 1849), ENV(32, 3131), ENV(37, 3111), ENV(114, 3103), ENV(164, 3116), ENV(180, 3116), ENV(181, 0), ENV(360, 0)];

enum envTrumAmp11 = [ENV(1, 0), ENV(2, 0), ENV(37, 6), ENV(55, 25), ENV(88, 29), ENV(114, 28), ENV(164, 3), ENV(186, 0), ENV(360, 0)];
enum envTrumFrq11 = [ENV(1, 0), ENV(2, 1398), ENV(31, 3419), ENV(42, 3419), ENV(91, 3419), ENV(106, 3406), ENV(150, 3421), ENV(186, 3421), ENV(187, 0), ENV(360, 0)];

enum envTrumAmp12 = [ENV(1, 0), ENV(7, 0), ENV(39, 3), ENV(43, 8), ENV(88, 11), ENV(118, 9), ENV(138, 3), ENV(165, 0), ENV(360, 0)];
enum envTrumFrq12 = [ENV(1, 0), ENV(6, 0), ENV(7, 1806), ENV(23, 2942), ENV(36, 2759), ENV(37, 3746), ENV(50, 3723), ENV(84, 3731), ENV(110, 3721), ENV(156, 3741), ENV(165, 3620), ENV(167, 0), ENV(360, 0)];

enum envOboeAmp01 = [ENV(1, 0), ENV(9, 0), ENV(14, 10), ENV(26, 10), ENV(52, 140), ENV(94, 187), ENV(153, 170), ENV(313, 0)];
enum envOboeFrq01 = [ENV(1, 0), ENV(8, 0), ENV(9, 314), ENV(25, 292), ENV(43, 311), ENV(144, 311), ENV(272, 313), ENV(313, 309)];

enum envOboeAmp02 = [ENV(1, 0), ENV(10, 0), ENV(26, 17), ENV(40, 139), ENV(159, 115), ENV(239, 62), ENV(307, 0), ENV(313, 0)];
enum envOboeFrq02 = [ENV(1, 0), ENV(9, 0), ENV(10, 708), ENV(16, 617), ENV(41, 625), ENV(105, 621), ENV(265, 630), ENV(307, 626), ENV(308, 0), ENV(313, 0)];

enum envOboeAmp03 = [ENV(1, 0), ENV(10, 0), ENV(25, 19), ENV(36, 163), ENV(71, 191), ENV(129, 187), ENV(297, 0), ENV(313, 0)];
enum envOboeFrq03 = [ENV(1, 0), ENV(9, 0), ENV(10, 915), ENV(21, 931), ENV(72, 938), ENV(148, 935), ENV(249, 941), ENV(297, 938), ENV(299, 0), ENV(313, 0)];

enum envOboeAmp04 = [ENV(1, 0), ENV(10, 0), ENV(25, 16), ENV(43, 221), ENV(64, 173), ENV(114, 171), ENV(284, 0), ENV(313, 0)];
enum envOboeFrq04 = [ENV(1, 0), ENV(9, 0), ENV(10, 1209), ENV(18, 1261), ENV(37, 1246), ENV(109, 1245), ENV(238, 1255), ENV(284, 1253), ENV(285, 0), ENV(313, 0)];

enum envOboeAmp05 = [ENV(1, 0), ENV(6, 0), ENV(13, 3), ENV(21, 0), ENV(28, 0), ENV(44, 210), ENV(59, 238), ENV(126, 224), ENV(199, 85), ENV(292, 0), ENV(313, 0)];
enum envOboeFrq05 = [ENV(1, 0), ENV(5, 0), ENV(6, 1553), ENV(21, 1582), ENV(25, 1237), ENV(28, 1533), ENV(35, 1564), ENV(56, 1557), ENV(113, 1555), ENV(185, 1565), ENV(292, 1566), ENV(293, 0), ENV(313, 0)];

enum envOboeAmp06 = [ENV(1, 0), ENV(13, 0), ENV(17, 1), ENV(24, 0), ENV(30, 0), ENV(41, 63), ENV(67, 40), ENV(121, 38), ENV(278, 0), ENV(313, 0)];
enum envOboeFrq06 = [ENV(1, 0), ENV(12, 0), ENV(13, 1907), ENV(22, 1883), ENV(28, 1544), ENV(30, 1856), ENV(36, 1878), ENV(52, 1871), ENV(113, 1866), ENV(169, 1878), ENV(225, 1876), ENV(278, 1891), ENV(280, 0), ENV(313, 0)];

enum envOboeAmp07 = [ENV(1, 0), ENV(8, 0), ENV(14, 0), ENV(21, 0), ENV(32, 0), ENV(37, 22), ENV(119, 12), ENV(146, 3), ENV(194, 8), ENV(256, 0), ENV(313, 0)];
enum envOboeFrq07 = [ENV(1, 0), ENV(6, 0), ENV(8, 1978), ENV(21, 1923), ENV(28, 1717), ENV(32, 2191), ENV(111, 2177), ENV(188, 2193), ENV(229, 2182), ENV(256, 2194), ENV(257, 0), ENV(313, 0)];

enum envOboeAmp08 = [ENV(1, 0), ENV(6, 0), ENV(14, 0), ENV(21, 0), ENV(37, 0), ENV(66, 5), ENV(106, 3), ENV(129, 4), ENV(199, 3), ENV(235, 0), ENV(313, 0)];
enum envOboeFrq08 = [ENV(1, 0), ENV(5, 0), ENV(6, 2506), ENV(21, 2491), ENV(25, 1252), ENV(37, 2523), ENV(56, 2495), ENV(110, 2489), ENV(140, 2491), ENV(195, 2502), ENV(235, 2505), ENV(237, 0), ENV(313, 0)];

enum envOboeAmp09 = [ENV(1, 0), ENV(4, 0), ENV(14, 0), ENV(20, 0), ENV(36, 0), ENV(45, 32), ENV(78, 24), ENV(132, 25), ENV(161, 15), ENV(241, 0), ENV(313, 0)];
enum envOboeFrq09 = [ENV(1, 0), ENV(2, 0), ENV(4, 2783), ENV(20, 2779), ENV(29, 1286), ENV(37, 2803), ENV(80, 2806), ENV(113, 2799), ENV(167, 2813), ENV(241, 2818), ENV(242, 0), ENV(313, 0)];

enum envOboeAmp10 = [ENV(1, 0), ENV(6, 0), ENV(17, 2), ENV(22, 0), ENV(35, 0), ENV(47, 121), ENV(144, 112), ENV(206, 21), ENV(242, 0), ENV(313, 0)];
enum envOboeFrq10 = [ENV(1, 0), ENV(5, 0), ENV(6, 3123), ENV(22, 3115), ENV(29, 2229), ENV(35, 3118), ENV(70, 3117), ENV(113, 3109), ENV(200, 3130), ENV(242, 3131), ENV(243, 0), ENV(313, 0)];

enum envOboeAmp11 = [ENV(1, 0), ENV(5, 0), ENV(17, 1), ENV(24, 0), ENV(37, 0), ENV(47, 70), ENV(123, 67), ENV(167, 44), ENV(188, 16), ENV(239, 0), ENV(313, 0)];
enum envOboeFrq11 = [ENV(1, 0), ENV(4, 0), ENV(5, 3285), ENV(24, 3388), ENV(29, 1270), ENV(37, 3430), ENV(76, 3429), ENV(110, 3423), ENV(194, 3444), ENV(239, 3444), ENV(241, 0), ENV(313, 0)];

enum envOboeAmp12 = [ENV(1, 0), ENV(14, 1), ENV(24, 0), ENV(37, 0), ENV(44, 49), ENV(79, 42), ENV(122, 46), ENV(185, 8), ENV(231, 0), ENV(313, 0)];
enum envOboeFrq12 = [ENV(1, 3627), ENV(24, 3664), ENV(29, 1690), ENV(37, 3739), ENV(90, 3742), ENV(115, 3733), ENV(187, 3760), ENV(231, 3763), ENV(233, 0), ENV(313, 0)];

enum envOboeAmp13 = [ENV(1, 0), ENV(4, 0), ENV(16, 0), ENV(24, 0), ENV(40, 0), ENV(47, 27), ENV(84, 22), ENV(126, 24), ENV(177, 7), ENV(229, 0), ENV(313, 0)];
enum envOboeFrq13 = [ENV(1, 0), ENV(2, 0), ENV(4, 4081), ENV(24, 4064), ENV(30, 1350), ENV(40, 4064), ENV(57, 4049), ENV(148, 4051), ENV(181, 4074), ENV(229, 4069), ENV(230, 0), ENV(313, 0)];

enum envOboeAmp14 = [ENV(1, 0), ENV(4, 0), ENV(16, 0), ENV(21, 0), ENV(41, 0), ENV(44, 13), ENV(63, 8), ENV(82, 7), ENV(111, 10), ENV(175, 0), ENV(
                        313, 0)];
enum envOboeFrq14 = [ENV(1, 0), ENV(2, 0), ENV(4, 4321), ENV(21, 4259), ENV(29, 1238), ENV(41, 4346), ENV(61, 4367), ENV(87, 4368), ENV(102, 4357), ENV(175, 4376), ENV(176, 0), ENV(313, 0)];

enum envOboeAmp15 = [ENV(1, 0), ENV(47, 0), ENV(72, 3), ENV(97, 3), ENV(121, 1), ENV(161, 2), ENV(175, 0), ENV(313, 0)];
enum envOboeFrq15 = [ENV(1, 0), ENV(45, 0), ENV(47, 3164), ENV(55, 4557), ENV(68, 4662), ENV(98, 4670), ENV(142, 4661), ENV(175, 4666), ENV(176, 0), ENV(313, 0)];

enum envOboeAmp16 = [ENV(1, 0), ENV(48, 0), ENV(61, 4), ENV(86, 4), ENV(126, 3), ENV(137, 5), ENV(161, 0), ENV(313, 0)];
enum envOboeFrq16 = [ENV(1, 0), ENV(47, 0), ENV(48, 4567), ENV(49, 4978), ENV(75, 4990), ENV(109, 4982), ENV(138, 4985), ENV(161, 4996), ENV(163, 0), ENV(313, 0)];

enum envOboeAmp17 = [ENV(1, 0), ENV(51, 0), ENV(61, 5), ENV(76, 3), ENV(132, 3), ENV(164, 2), ENV(173, 0), ENV(313, 0)];
enum envOboeFrq17 = [ENV(1, 0), ENV(49, 0), ENV(51, 4634), ENV(55, 5313), ENV(66, 5301), ENV(99, 5301), ENV(129, 5292), ENV(173, 5318), ENV(175, 0), ENV(313, 0)];

enum envOboeAmp18 = [ENV(1, 0), ENV(52, 0), ENV(63, 2), ENV(91, 3), ENV(126, 3), ENV(156, 2), ENV(168, 0), ENV(313, 0)];
enum envOboeFrq18 = [ENV(1, 0), ENV(51, 0), ENV(52, 4729), ENV(59, 5606), ENV(92, 5611), ENV(122, 5605), ENV(152, 5611), ENV(168, 5628), ENV(169, 0), ENV(313, 0)];

enum envOboeAmp19 = [ENV(1, 0), ENV(47, 0), ENV(56, 2), ENV(80, 1), ENV(117, 2), ENV(159, 1), ENV(176, 0), ENV(313, 0)];
enum envOboeFrq19 = [ENV(1, 0), ENV(45, 0), ENV(47, 5772), ENV(57, 5921), ENV(86, 5928), ENV(114, 5914), ENV(150, 5938), ENV(176, 5930), ENV(177, 0), ENV(313, 0)];

enum envOboeAmp20 = [ENV(1, 0), ENV(49, 0), ENV(57, 2), ENV(83, 2), ENV(109, 1), ENV(159, 3), ENV(195, 0), ENV(313, 0)];
enum envOboeFrq20 = [ENV(1, 0), ENV(48, 0), ENV(49, 5369), ENV(57, 6268), ENV(76, 6230), ENV(145, 6234), ENV(184, 6263), ENV(195, 6244), ENV(196, 0), ENV(313, 0)];

enum envOboeAmp21 = [ENV(1, 0), ENV(57, 0), ENV(61, 0), ENV(88, 1), ENV(113, 0), ENV(129, 1), ENV(140, 0), ENV(313, 0)];
enum envOboeFrq21 = [ENV(1, 0), ENV(56, 0), ENV(57, 5477), ENV(61, 6440), ENV(71, 6550), ENV(97, 6538), ENV(122, 6554), ENV(140, 6548), ENV(141, 0), ENV(313, 0)];

enum envClarAmp01 = [ENV(1, 0), ENV(7, 0), ENV(20, 6), ENV(32, 73), ENV(48, 445), ENV(199, 361), ENV(330, 0)];
enum envClarFrq01 = [ENV(1, 0), ENV(6, 0), ENV(7, 282), ENV(19, 368), ENV(21, 314), ENV(46, 310), ENV(141, 312), ENV(284, 313), ENV(330, 314)];

enum envClarAmp02 = [ENV(1, 0), ENV(24, 0), ENV(43, 22), ENV(104, 2), ENV(193, 4), ENV(238, 10), ENV(301, 0), ENV(330, 0)];
enum envClarFrq02 = [ENV(1, 0), ENV(23, 0), ENV(24, 629), ENV(68, 619), ENV(116, 616), ENV(167, 633), ENV(223, 624), ENV(301, 627), ENV(302, 0), ENV(330, 0)];

enum envClarAmp03 = [ENV(1, 0), ENV(15, 0), ENV(37, 12), ENV(48, 159), ENV(204, 122), ENV(286, 17), ENV(309, 0), ENV(330, 0)];
enum envClarFrq03 = [ENV(1, 0), ENV(14, 0), ENV(15, 803), ENV(24, 928), ENV(36, 898), ENV(46, 931), ENV(113, 939), ENV(330, 942)];

enum envClarAmp04 = [ENV(1, 0), ENV(9, 0), ENV(19, 2), ENV(24, 0), ENV(39, 0), ENV(49, 26), ENV(103, 3), ENV(167, 5), ENV(229, 10), ENV(291, 0), ENV(330, 0)];
enum envClarFrq04 = [ENV(1, 0), ENV(7, 0), ENV(9, 1261), ENV(24, 1314), ENV(30, 327), ENV(39, 1245), ENV(105, 1243), ENV(215, 1257), ENV(246, 1249), ENV(291, 1261), ENV(292, 0), ENV(330, 0)];

enum envClarAmp05 = [ENV(1, 0), ENV(6, 0), ENV(18, 5), ENV(25, 0), ENV(39, 0), ENV(54, 375), ENV(212, 210), ENV(266, 20), ENV(295, 0), ENV(330, 0)];
enum envClarFrq05 = [ENV(1, 0), ENV(5, 0), ENV(6, 1572), ENV(25, 1528), ENV(32, 911), ENV(38, 1560), ENV(67, 1554), ENV(127, 1565), ENV(308, 1569), ENV(309, 0), ENV(330, 0)];

enum envClarAmp06 = [ENV(1, 0), ENV(3, 0), ENV(11, 0), ENV(15, 0), ENV(41, 0), ENV(48, 25), ENV(108, 4), ENV(216, 12), ENV(282, 0), ENV(330, 0)];
enum envClarFrq06 = [ENV(1, 0), ENV(2, 0), ENV(3, 1934), ENV(12, 1890), ENV(33, 320), ENV(46, 1862), ENV(186, 1883), ENV(282, 1875), ENV(283, 0), ENV(330, 0)];

enum envClarAmp07 = [ENV(1, 0), ENV(2, 0), ENV(18, 1), ENV(24, 0), ENV(42, 0), ENV(52, 108), ENV(127, 46), ENV(177, 42), ENV(253, 0), ENV(330, 0)];
enum envClarFrq07 = [ENV(1, 0), ENV(2, 2180), ENV(24, 2148), ENV(34, 795), ENV(43, 2167), ENV(113, 2193), ENV(253, 2192), ENV(255, 0), ENV(330, 0)];

enum envClarAmp08 = [ENV(1, 0), ENV(2, 0), ENV(14, 1), ENV(23, 0), ENV(43, 0), ENV(52, 83), ENV(110, 17), ENV(199, 18), ENV(242, 0), ENV(330, 0)];
enum envClarFrq08 = [ENV(1, 0), ENV(2, 2458), ENV(23, 2343), ENV(33, 328), ENV(45, 2472), ENV(125, 2507), ENV(242, 2510), ENV(243, 0), ENV(330, 0)];

enum envClarAmp09 = [ENV(1, 0), ENV(5, 0), ENV(20, 2), ENV(21, 3), ENV(27, 0), ENV(42, 0), ENV(55, 127), ENV(132, 73), ENV(163, 71), ENV(255, 0), ENV(330, 0)];
enum envClarFrq09 = [ENV(1, 0), ENV(3, 0), ENV(5, 2849), ENV(27, 2688), ENV(33, 964), ENV(42, 2792), ENV(128, 2822), ENV(255, 2819), ENV(256, 0), ENV(330, 0)];

enum envClarAmp10 = [ENV(1, 0), ENV(5, 0), ENV(23, 1), ENV(30, 0), ENV(47, 0), ENV(54, 32), ENV(92, 17), ENV(232, 7), ENV(247, 0), ENV(330, 0)];
enum envClarFrq10 = [ENV(1, 0), ENV(3, 0), ENV(5, 3173), ENV(30, 3030), ENV(39, 2320), ENV(50, 3096), ENV(134, 3136), ENV(247, 3138), ENV(248, 0), ENV(330, 0)];

enum envClarAmp11 = [ENV(1, 0), ENV(23, 1), ENV(28, 0), ENV(39, 0), ENV(59, 44), ENV(122, 26), ENV(153, 26), ENV(262, 0), ENV(330, 0)];
enum envClarFrq11 = [ENV(1, 3313), ENV(28, 3279), ENV(34, 1768), ENV(43, 3420), ENV(127, 3448), ENV(262, 3441), ENV(264, 0), ENV(330, 0)];

enum envClarAmp12 = [ENV(1, 0), ENV(10, 2), ENV(21, 0), ENV(46, 0), ENV(52, 53), ENV(158, 9), ENV(206, 28), ENV(255, 0), ENV(330, 0)];
enum envClarFrq12 = [ENV(1, 3756), ENV(21, 3728), ENV(33, 2095), ENV(47, 3741), ENV(136, 3762), ENV(255, 3759), ENV(256, 0), ENV(330, 0)];

enum envClarAmp13 = [ENV(1, 0), ENV(3, 0), ENV(16, 1), ENV(29, 0), ENV(41, 0), ENV(46, 24), ENV(52, 8), ENV(77, 57), ENV(192, 8), ENV(250, 0), ENV(330, 0)];
enum envClarFrq13 = [ENV(1, 0), ENV(2, 0), ENV(3, 4152), ENV(29, 3868), ENV(36, 2240), ENV(46, 4045), ENV(85, 4049), ENV(128, 4078), ENV(181, 4078), ENV(250, 4103), ENV(251, 0), ENV(330, 0)];

enum envClarAmp14 = [ENV(1, 0), ENV(3, 0), ENV(16, 0), ENV(20, 0), ENV(48, 0), ENV(56, 38), ENV(110, 3), ENV(188, 14), ENV(228, 0), ENV(330, 0)];
enum envClarFrq14 = [ENV(1, 0), ENV(2, 0), ENV(3, 4213), ENV(20, 4119), ENV(36, 1566), ENV(48, 4344), ENV(130, 4388), ENV(228, 4388), ENV(229, 0), ENV(330, 0)];

enum envClarAmp15 = [ENV(1, 0), ENV(5, 0), ENV(23, 1), ENV(28, 0), ENV(50, 0), ENV(77, 14), ENV(202, 1), ENV(219, 2), ENV(247, 0), ENV(330, 0)];
enum envClarFrq15 = [ENV(1, 0), ENV(3, 0), ENV(5, 4624), ENV(28, 4496), ENV(33, 1012), ENV(48, 4649), ENV(122, 4703), ENV(247, 4685), ENV(248, 0), ENV(330, 0)];

enum envClarAmp16 = [ENV(1, 0), ENV(14, 0), ENV(24, 0), ENV(38, 0), ENV(64, 12), ENV(104, 4), ENV(145, 4), ENV(215, 1), ENV(238, 0), ENV(330, 0)];
enum envClarFrq16 = [ENV(1, 4928), ENV(24, 4751), ENV(36, 1072), ENV(52, 4965), ENV(117, 5006), ENV(155, 5003), ENV(198, 5020), ENV(238, 3197), ENV(239, 0), ENV(330, 0)];

enum envClarAmp17 = [ENV(1, 0), ENV(58, 0), ENV(95, 12), ENV(136, 13), ENV(201, 1), ENV(220, 3), ENV(233, 0), ENV(330, 0)];
enum envClarFrq17 = [ENV(1, 0), ENV(45, 0), ENV(46, 5005), ENV(58, 3759), ENV(63, 5285), ENV(119, 5325), ENV(180, 5325), ENV(233, 5367), ENV(234, 0), ENV(330, 0)];

enum envClarAmp18 = [ENV(1, 0), ENV(50, 0), ENV(61, 5), ENV(100, 0), ENV(141, 4), ENV(185, 2), ENV(208, 0), ENV(330, 0)];
enum envClarFrq18 = [ENV(1, 0), ENV(48, 0), ENV(50, 4926), ENV(52, 5563), ENV(94, 5628), ENV(113, 5602), ENV(137, 5634), ENV(208, 5646), ENV(210, 0), ENV(330, 0)];

enum envClarAmp19 = [ENV(1, 0), ENV(58, 0), ENV(63, 1), ENV(85, 0), ENV(140, 1), ENV(171, 0), ENV(183, 0), ENV(330, 0)];
enum envClarFrq19 = [ENV(1, 0), ENV(56, 0), ENV(58, 3938), ENV(65, 5753), ENV(79, 5930), ENV(104, 5889), ENV(152, 5916), ENV(183, 5880), ENV(184, 0), ENV(330, 0)];

enum envClarAmp20 = [ENV(1, 0), ENV(50, 0), ENV(64, 5), ENV(103, 1), ENV(139, 1), ENV(177, 2), ENV(219, 0), ENV(330, 0)];
enum envClarFrq20 = [ENV(1, 0), ENV(48, 0), ENV(50, 5192), ENV(58, 6209), ENV(121, 6266), ENV(190, 6266), ENV(204, 6238), ENV(219, 6288), ENV(220, 0), ENV(330, 0)];

enum envClarAmp21 = [ENV(1, 0), ENV(70, 0), ENV(79, 3), ENV(113, 3), ENV(141, 1), ENV(206, 1), ENV(219, 0), ENV(330, 0)];
enum envClarFrq21 = [ENV(1, 0), ENV(69, 0), ENV(70, 4245), ENV(77, 6537), ENV(116, 6567), ENV(140, 6571), ENV(176, 6564), ENV(219, 6583), ENV(220, 0), ENV(330, 0)];

enum trumArr =  
[
    PRT(envTrumAmp01, envTrumFrq01),
    PRT(envTrumAmp02, envTrumFrq02),
    PRT(envTrumAmp03, envTrumFrq03),
    PRT(envTrumAmp04, envTrumFrq04),
    PRT(envTrumAmp05, envTrumFrq05), 
    PRT(envTrumAmp06, envTrumFrq06), 
    PRT(envTrumAmp07, envTrumFrq07), 
    PRT(envTrumAmp08, envTrumFrq08), 
    PRT(envTrumAmp09, envTrumFrq09), 
    PRT(envTrumAmp10, envTrumFrq10), 
    PRT(envTrumAmp11, envTrumFrq11), 
    PRT(envTrumAmp12, envTrumFrq12),
];

enum oboeArr =
[
    PRT(envOboeAmp01, envOboeFrq01),
    PRT(envOboeAmp02, envOboeFrq02),
    PRT(envOboeAmp03, envOboeFrq03),
    PRT(envOboeAmp04, envOboeFrq04),
    PRT(envOboeAmp05, envOboeFrq05),
    PRT(envOboeAmp06, envOboeFrq06),
    PRT(envOboeAmp07, envOboeFrq07),
    PRT(envOboeAmp08, envOboeFrq08),
    PRT(envOboeAmp09, envOboeFrq09),
    PRT(envOboeAmp10, envOboeFrq10),
    PRT(envOboeAmp11, envOboeFrq11),
    PRT(envOboeAmp12, envOboeFrq12),
    PRT(envOboeAmp13, envOboeFrq13),
    PRT(envOboeAmp14, envOboeFrq14),
    PRT(envOboeAmp15, envOboeFrq15),
    PRT(envOboeAmp16, envOboeFrq16),
    PRT(envOboeAmp17, envOboeFrq17),
    PRT(envOboeAmp18, envOboeFrq18),
    PRT(envOboeAmp19, envOboeFrq19),
    PRT(envOboeAmp20, envOboeFrq20),
    PRT(envOboeAmp21, envOboeFrq21),
];

enum clarArr =
[
    PRT(envClarAmp01, envClarFrq01),
    PRT(envClarAmp02, envClarFrq02),
    PRT(envClarAmp03, envClarFrq03),
    PRT(envClarAmp04, envClarFrq04),
    PRT(envClarAmp05, envClarFrq05),
    PRT(envClarAmp06, envClarFrq06),
    PRT(envClarAmp07, envClarFrq07),
    PRT(envClarAmp08, envClarFrq08),
    PRT(envClarAmp09, envClarFrq09),
    PRT(envClarAmp10, envClarFrq10),
    PRT(envClarAmp11, envClarFrq11),
    PRT(envClarAmp12, envClarFrq12),
    PRT(envClarAmp13, envClarFrq13),
    PRT(envClarAmp14, envClarFrq14),
    PRT(envClarAmp15, envClarFrq15),
    PRT(envClarAmp16, envClarFrq16),
    PRT(envClarAmp17, envClarFrq17),
    PRT(envClarAmp18, envClarFrq18),
    PRT(envClarAmp19, envClarFrq19),
    PRT(envClarAmp20, envClarFrq20),
    PRT(envClarAmp21, envClarFrq21),
];

INS insTrum = INS(360, trumArr);
INS insOboe = INS(313, oboeArr);
INS insClar = INS(330, clarArr);
