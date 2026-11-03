;; =====================================================================
;;  UPI ADOPTION SIMULATOR
;;  An Agent-Based Bass Diffusion Model of Digital-Payment Adoption
;;
;;  Project : Agent-Based Modeling in Economics
;;  College : Faculty of Technology, University of Delhi
;;  Course  : B.Tech CSE, 2nd Year, Semester 3
;;  Based on: Delli Gatti et al. (2018), "Agent-Based Models in
;;            Economics: A Toolkit", Cambridge Univ. Press, Ch. 7.3.4
;;
;;  Core behavioural rule (book, Eq. 7.9):
;;      Pr(adopt) for person i at time t  =  p  +  q * A(i,t)
;;      p      = innovation coefficient  (advertising / external push)
;;      q      = imitation coefficient   (word-of-mouth / peers)
;;      A(i,t) = share of i's friends who already use UPI
;; =====================================================================

globals [
  time-to-50       ;; tick at which 50% of the population adopted (-1 = not yet)
  peak-tick        ;; tick with the highest number of new adopters
  peak-new         ;; number of new adopters at that peak
  new-by-ads       ;; new adopters this tick because of advertising (innovators)
  new-by-wom       ;; new adopters this tick because of friends (imitators)
  bass-F           ;; classical aggregate Bass model benchmark (fully mixed)
  hazard           ;; share of remaining non-users who adopted this week (ABM)
  bass-hazard      ;; theoretical Bass adoption rate p + q*F(t) (book, Eq. 7.7)
  p-eff            ;; effective p after policy
  q-eff            ;; effective q after policy
  ;; colours
  bg-color non-adopter-color ads-color wom-color seed-color
  link-color active-link-color
]

turtles-own [
  adopted?         ;; true once the person uses UPI
  adopted-via      ;; "none", "ads", "wom" or "seed"
  p-i              ;; personal innovativeness (p for this agent)
  q-i              ;; personal sensitivity to friends (q for this agent)
  base-size        ;; drawing size (bigger = more connected)
  just-adopted?    ;; used for the white "flash" when someone adopts
  pending          ;; decision taken this tick (synchronous update)
]

;; ---------------------------------------------------------------------
;;  SETUP
;; ---------------------------------------------------------------------

to setup
  clear-all
  set-colors
  ask patches [ set pcolor bg-color ]
  apply-policy
  make-agents
  build-network
  style-network
  seed-adopters
  set time-to-50 -1
  set peak-tick 0
  set peak-new 0
  set bass-F fraction-adopted
  reset-ticks
end

to set-colors
  set bg-color          [11 15 30]
  set non-adopter-color [95 105 135]
  set ads-color         [30 170 255]
  set wom-color         [50 230 120]
  set seed-color        [255 196 0]
  set link-color        [38 46 72]
  set active-link-color [30 120 80]
end

;; Policy experiments change the effective p and q
to apply-policy
  set p-eff p
  set q-eff q
  if policy = "Advertising campaign (p x3)" [ set p-eff p * 3 ]
  if policy = "Referral cashback (q x2)"    [ set q-eff q * 2 ]
  if policy = "Ads + cashback"              [ set p-eff p * 3  set q-eff q * 2 ]
  set p-eff min list 1 p-eff
  set q-eff min list 1 q-eff
end

to make-agents
  create-turtles num-agents [
    set shape "circle"
    set adopted? false
    set adopted-via "none"
    set just-adopted? false
    set pending ""
    ifelse heterogeneous? [
      ;; people differ: some are early adopters, some are sceptics
      set p-i max list 0 (random-normal p-eff (p-eff / 2))
      set q-i max list 0 (random-normal q-eff (q-eff / 2))
    ] [
      set p-i p-eff
      set q-i q-eff
    ]
    setxy (min-pxcor + 1 + random-float (world-width - 3))
          (min-pycor + 1 + random-float (world-height - 3))
  ]
end

;; ---------------------------------------------------------------------
;;  SOCIAL NETWORK  (book, Ch. 6: interaction and networks)
;; ---------------------------------------------------------------------

to build-network
  if network-type = "Small-world"              [ build-small-world ]
  if network-type = "Random"                   [ build-random ]
  if network-type = "Scale-free (influencers)" [ build-scale-free ]
  ;; "Fully mixed (classical Bass)": no links, everyone sees everyone
end

;; People link to their nearest neighbours (local clusters, like a
;; locality or hostel), then a fraction of links is rewired to random
;; people far away (relatives, college friends): a small world.
to build-small-world
  let target round (num-agents * avg-links / 2)
  let k 1
  while [ count links < target and k < num-agents ] [
    ask turtles [ create-links-with min-n-of k other turtles [ distance myself ] ]
    set k k + 1
  ]
  if count links > target [ ask n-of (count links - target) links [ die ] ]
  let to-rewire links with [ random-float 1 < rewire-prob ]
  ask to-rewire [
    let a end1
    let candidates turtles with [ self != a and not link-neighbor? a ]
    if any? candidates [
      let b one-of candidates
      ask a [ create-link-with b ]
      die
    ]
  ]
end

;; Erdos-Renyi random network with the chosen average degree
to build-random
  let target round (num-agents * avg-links / 2)
  while [ count links < target ] [
    ask one-of turtles [ create-link-with one-of other turtles ]
  ]
  repeat 25 [ layout-spring turtles links 0.3 3 1.2 ]
end

;; Preferential attachment (Barabasi-Albert): new people prefer to
;; connect to already popular people -> a few big "influencers"
to build-scale-free
  let m max list 1 round (avg-links / 2)
  let ordered sort turtles
  let core sublist ordered 0 (min list num-agents (m + 1))
  foreach core [ a -> foreach core [ b -> if a != b [ ask a [ create-link-with b ] ] ] ]
  foreach sublist ordered (length core) (length ordered) [ t ->
    let partners no-turtles
    while [ count partners < m ] [
      let cand [ one-of both-ends ] of one-of links
      set partners (turtle-set partners cand)
    ]
    ask t [ create-links-with partners ]
  ]
  ask turtles [ setxy (0.6 * random-xcor) (0.6 * random-ycor) ]
  ;; hubs in the centre, everyone else around them
  repeat 60 [ layout-spring turtles links 0.15 4.5 6 ]
end

to style-network
  ask turtles [
    set base-size min list 3.2 (0.75 + 0.22 * sqrt count my-links)
    set size base-size
    set color non-adopter-color
  ]
  ask links [
    set color link-color
    set hidden? not show-links?
  ]
end

to seed-adopters
  let n min list num-seeds num-agents
  if seed-strategy = "Random people" [
    ask n-of n turtles [ adopt "seed" ]
  ]
  if seed-strategy = "Top influencers" [
    ask max-n-of n turtles [ count my-links ] [ adopt "seed" ]
  ]
end

;; ---------------------------------------------------------------------
;;  GO  (book, Ch. 3: an ABM is a recursive system X(t+1) = F(X(t)))
;; ---------------------------------------------------------------------

to go
  ;; end of the white flash from last tick
  ask turtles with [ just-adopted? ] [
    set just-adopted? false
    set size base-size
    set color adopter-color
  ]
  if (all? turtles [ adopted? ]) or (ticks >= 500) [
    recolor-links
    display
    stop
  ]

  let global-share fraction-adopted
  let remaining count turtles with [ not adopted? ]
  let mixed? (network-type = "Fully mixed (classical Bass)")

  ;; 1) every non-user decides, based on the state at the START of the tick
  ask turtles with [ not adopted? ] [
    let A ifelse-value mixed? [ global-share ] [ local-share ]
    let r random-float 1
    ifelse r < p-i
      [ set pending "ads" ]                          ;; convinced by advertising
      [ if r < p-i + q-i * A [ set pending "wom" ] ] ;; convinced by friends
  ]
  ;; 2) all decisions are applied together (synchronous update)
  ask turtles with [ pending != "" ] [
    adopt pending
    set pending ""
  ]

  set new-by-ads count turtles with [ just-adopted? and adopted-via = "ads" ]
  set new-by-wom count turtles with [ just-adopted? and adopted-via = "wom" ]
  set hazard ifelse-value remaining > 0 [ (new-by-ads + new-by-wom) / remaining ] [ 0 ]
  set bass-hazard min list 1 (p-eff + q-eff * global-share)
  if new-by-ads + new-by-wom > peak-new [
    set peak-new new-by-ads + new-by-wom
    set peak-tick ticks + 1
  ]

  ;; classical aggregate Bass equation, same p and q, for comparison
  set bass-F bass-F + (1 - bass-F) * (min list 1 (p-eff + q-eff * bass-F))

  recolor-links
  tick
  if time-to-50 < 0 and fraction-adopted >= 0.5 [ set time-to-50 ticks ]
end

to adopt [ reason ]
  set adopted? true
  set adopted-via reason
  set just-adopted? true
  set color flash-color
  set size base-size * 1.45
end

to recolor-links
  if show-links? [
    ask links with [ color != active-link-color and all? both-ends [ adopted? ] ] [
      set color active-link-color
    ]
  ]
end

;; ---------------------------------------------------------------------
;;  REPORTERS  (used by monitors, plots and BehaviorSpace)
;; ---------------------------------------------------------------------

to-report adopter-color
  if adopted-via = "ads"  [ report ads-color ]
  if adopted-via = "wom"  [ report wom-color ]
  if adopted-via = "seed" [ report seed-color ]
  report non-adopter-color
end

to-report flash-color
  if adopted-via = "ads"  [ report [170 225 255] ]
  if adopted-via = "wom"  [ report [190 255 210] ]
  report [255 235 150]
end

to-report local-share
  let nbrs link-neighbors
  if not any? nbrs [ report 0 ]
  report (count nbrs with [ adopted? ]) / (count nbrs)
end

to-report fraction-adopted
  report (count turtles with [ adopted? ]) / (count turtles)
end

to-report pct-adopted
  report 100 * fraction-adopted
end

to-report num-adopters
  report count turtles with [ adopted? ]
end

to-report pct-via [ reason ]
  let users count turtles with [ adopted? ]
  if users = 0 [ report 0 ]
  report 100 * (count turtles with [ adopted-via = reason ]) / users
end

to-report avg-degree
  if network-type = "Fully mixed (classical Bass)" [ report num-agents - 1 ]
  report 2 * count links / count turtles
end

to-report time-to-50-label
  ifelse time-to-50 < 0 [ report "not yet" ] [ report time-to-50 ]
end

to-report all-adopted?
  report all? turtles [ adopted? ]
end
@#$#@#$#@
GRAPHICS-WINDOW
288
16
784
535
-1
-1
6.0
1
12
1
1
1
0
0
0
1
-40
40
-40
40
1
1
1
Time step (weeks)
30.0

TEXTBOX
12
10
272
36
UPI ADOPTION SIMULATOR
18
105.0
1

TEXTBOX
12
36
274
70
Agent-based Bass diffusion model of digital-payment adoption on a social network
10
4.0
1

TEXTBOX
12
74
274
95
1 | POPULATION & SOCIAL NETWORK
11
103.0
1

SLIDER
12
98
273
131
num-agents
num-agents
100
2000
1000
50
1
people
HORIZONTAL

CHOOSER
12
136
273
181
network-type
network-type
"Small-world" "Random" "Scale-free (influencers)" "Fully mixed (classical Bass)"
0

SLIDER
12
187
273
220
avg-links
avg-links
1
30
5
1
1
friends
HORIZONTAL

TEXTBOX
12
230
273
250
2 | BEHAVIOUR  (Pr = p + q x A)
11
103.0
1

SLIDER
12
252
273
285
p
p
0
0.2
0.03
0.005
1
ads
HORIZONTAL

SLIDER
12
291
273
324
q
q
0
1
0.4
0.05
1
friends
HORIZONTAL

TEXTBOX
12
335
273
354
3 | POLICY EXPERIMENTS
11
103.0
1

CHOOSER
12
358
273
403
policy
policy
"None" "Advertising campaign (p x3)" "Referral cashback (q x2)" "Ads + cashback"
0

CHOOSER
12
409
273
454
seed-strategy
seed-strategy
"None" "Random people" "Top influencers"
0

SLIDER
12
460
273
493
num-seeds
num-seeds
0
50
10
1
1
seeds
HORIZONTAL

BUTTON
12
509
140
555
Setup
setup
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
146
509
273
555
Go
go
T
1
T
OBSERVER
NIL
G
NIL
NIL
0

TEXTBOX
12
565
270
582
LEGEND
10
0.0
1

TEXTBOX
12
583
138
601
● Grey: Not adopted
10
3.0
1

TEXTBOX
138
583
274
601
● Blue: Advertising
10
104.0
1

TEXTBOX
12
605
150
625
● Green: Friends
10
54.0
1

TEXTBOX
150
605
274
625
● Gold: Seeded user
10
44.0
1

TEXTBOX
12
629
273
664
Bright flash = adopted this week.  Bigger dot = more friends.
10
3.0
1

MONITOR
288
543
448
597
% on UPI
pct-adopted
1
1
13

MONITOR
454
543
614
597
Users
num-adopters
0
1
13

MONITOR
620
543
780
597
Week
ticks
0
1
13

MONITOR
288
604
448
657
50% week
time-to-50-label
0
1
13

MONITOR
454
604
614
657
New: ads
new-by-ads
0
1
12

MONITOR
620
604
780
657
New: friends
new-by-wom
0
1
12

PLOT
802
16
1391
262
S-curve: % of population using UPI
weeks
% adopted
0
30
0
100
true
true
"" ""
PENS
"Agent-based model" 1.0 0 -14109606 true "" "plot pct-adopted"
"Classical Bass equation" 1.0 0 -1015276 true "" "plot 100 * bass-F"

PLOT
802
274
1391
524
New users per week: ads vs friends
weeks
new users
0
30
0
50
true
true
"" ""
PENS
"Total" 1.0 0 -10855836 true "" "plot new-by-ads + new-by-wom"
"Via advertising (innovators)" 1.0 0 -14775066 true "" "plot new-by-ads"
"Via friends (imitators)" 1.0 0 -14109606 true "" "plot new-by-wom"

TEXTBOX
814
549
1382
568
MAIN QUESTION  /  HOW DOES UPI SPREAD?
12
103.0
1

TEXTBOX
814
575
1378
639
One dot = one person. Blue = adopted from external influence; green = adopted from peers. Compare the S-curve and weekly adoption to explain how individual decisions create market growth.
12
4.0
1

TEXTBOX
12
710
800
730
ADVANCED SETTINGS | unchanged model logic (scroll down only if needed)
11
103.0
1

SLIDER
12
737
274
770
rewire-prob
rewire-prob
0
1
0.1
0.05
1
NIL
HORIZONTAL

SWITCH
281
737
445
770
show-links?
show-links?
1
1
-1000

SWITCH
453
737
627
770
heterogeneous?
heterogeneous?
1
1
-1000
@#$#@#$#@
## WHAT IS IT?

**UPI Adoption Simulator** is an agent-based model (ABM) of how a new technology, here **UPI / digital payments**, spreads through a population.

Each of the 1,000 people (agents) decides each week whether to start using UPI. Two forces drive the decision:

* **Advertising (p)** is an external push: TV ads, government campaigns, posters at shops.
* **Word-of-mouth (q)** is the influence of friends who already use UPI.

Nobody programs the market-level adoption curve. It **emerges** from the individual decisions, which is the central idea of agent-based economics.

The model is the agent-based version of the **Bass diffusion model** (Bass, 1969), following Section 7.3.4 of *Agent-Based Models in Economics: A Toolkit* (Delli Gatti, Fagiolo, Gallegati, Richiardi & Russo, Cambridge University Press, 2018).

*Project: Agent-Based Modeling in Economics, Faculty of Technology, University of Delhi, B.Tech CSE, 2nd Year, Semester 3.*

## HOW IT WORKS

Every week (tick), every person *i* who does not use UPI yet adopts with probability

    Pr(adopt) = p + q × A(i,t)

where **A(i,t)** is the share of person *i*'s friends who already use UPI (book, Eq. 7.9).

* If the random draw is below **p**, the person adopts **because of advertising**. These people are the "innovators" and are shown in **blue**.
* Otherwise, if the draw is below **p + q·A**, the person adopts **because of friends**. These are the "imitators" and are shown in **green**.

All decisions in a week are based on the situation at the start of that week. Everyone updates together (synchronous update). This makes the model a **recursive system** X(t+1) = F(X(t), θ, ε), as described in Chapter 3 of the book.

**Social networks** (book, Chapter 6):

* **Small-world**: each person links to their nearest neighbours (a locality or a hostel), and a fraction `rewire-prob` of links is rewired to random distant people (relatives, college friends). This is the network the book uses.
* **Random**: links are placed between random pairs of people.
* **Scale-free (influencers)**: new people prefer to connect to already-popular people, so a few big hubs appear.
* **Fully mixed (classical Bass)**: no network. Everyone is influenced by the whole population, as in the original aggregate Bass equation.

The **orange line** in the S-curve plot is the classical aggregate Bass equation with the same p and q, F(t+1) = F(t) + (1 − F(t))(p + qF(t)). It lets you compare the "mainstream" equation with the agent-based result.

## HOW TO USE IT

1. Choose the population size, network type and average number of friends.
2. Set **p** (advertising) and **q** (word-of-mouth). The defaults p = 0.03, q = 0.4, n = 5 are the book's reference values, and also typical empirical values (Mahajan, Muller & Bass, 1995).
3. Optionally choose a **policy** or a **seed strategy**.
4. Press **Setup**, then **Go**. For each experiment change parameters and press **Setup** again.

**Monitors:** % using UPI, current number of users, current week, first week reaching 50% adoption, new adopters via ads, and new adopters via friends.

**Plots:**
1. **S-curve**: cumulative adoption, ABM vs. classical Bass equation.
2. **New users per week**: the bell-shaped curve, split into innovators and imitators.
Advanced network settings are below the main dashboard; the model and BehaviorSpace experiments are unchanged.

## THINGS TO NOTICE

* Adoption is slow at first. Only a few people adopt because of ads. Then word-of-mouth takes over and adoption **takes off**, and finally it **saturates**. This is the S-curve seen for real products.
* In the small-world network, green "clusters" grow around early adopters like ink spreading on paper.
* Early on most adopters are blue (ads). Later almost all are green (friends).
* Users have more friends on average than non-users. Connected people hear about UPI first.

## THINGS TO TRY

* **Advertising effect:** move p from 0.01 to 0.15. How much faster is 50% adoption reached? The book finds that **p has the strongest effect**.
* **Word-of-mouth effect:** move q from 0 to 1. The curves become similar once q is high.
* **Connectivity:** move avg-links from 1 to 30. Beyond about **6 friends** the result barely changes (book, Fig. 7.2).
* **Policy:** compare an advertising campaign with referral cashback. Which policy reaches 50% sooner?
* **Influencers:** choose the scale-free network, set p very low (0.005), and compare seeding 10 *random people* with seeding the 10 *top influencers*.
* **Heterogeneity:** the `heterogeneous?` control is in the advanced settings section beneath the main dashboard; keep it off for baseline experiments.

## EXTENDING THE MODEL

* Add a cost of adoption, or dis-adoption (people who stop using UPI).
* Add population groups (urban/rural, age) with different p and q.
* Add competing payment apps.
* Calibrate p and q to real UPI transaction data (book, Chapters 8–9).

## NETLOGO FEATURES

Uses `layout-spring` for network layouts, `min-n-of` for nearest-neighbour links, RGB colours, and **BehaviorSpace** experiments E1–E7 (Tools → BehaviorSpace) for the sensitivity analysis described in Chapter 7 of the book.

## RELATED MODELS

* Virus on a Network (NetLogo Models Library)
* Segregation (Wilensky, 1997), discussed in Chapter 2 of the book

## CREDITS AND REFERENCES

* Delli Gatti, D., Fagiolo, G., Gallegati, M., Richiardi, M. & Russo, A. (eds.) (2018). *Agent-Based Models in Economics: A Toolkit*. Cambridge University Press.
* Bass, F. M. (1969). A New Product Growth for Model Consumer Durables. *Management Science*, 15(5), 215–227.
* Mahajan, V., Muller, E. & Bass, F. M. (1995). Diffusion of New Products: Empirical Generalizations and Managerial Uses. *Marketing Science*, 14(3).
* Watts, D. J. & Strogatz, S. H. (1998). Collective dynamics of 'small-world' networks. *Nature*, 393, 440–442.
* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.


## CLASSROOM DASHBOARD

The main screen intentionally contains two plots and six monitors. The advanced controls `rewire-prob`, `show-links?`, and `heterogeneous?` remain as widgets below the main view because the original model and all seven BehaviorSpace experiments depend on them. Default `show-links?` is OFF to make the network readable. They are not deleted from the model.

**Model limitation:** The adoption coefficients are illustrative parameters from diffusion literature, not estimates from UPI user data. The model does not estimate advertising cost or real-world ROI.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="E1 Baseline S-curve" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <exitCondition>all-adopted?</exitCondition>
    <metric>pct-adopted</metric>
    <metric>new-by-ads</metric>
    <metric>new-by-wom</metric>
    <metric>100 * bass-F</metric>
    <enumeratedValueSet variable="num-agents"><value value="1000"/></enumeratedValueSet>
    <enumeratedValueSet variable="network-type"><value value="&quot;Small-world&quot;"/></enumeratedValueSet>
    <enumeratedValueSet variable="avg-links"><value value="5"/></enumeratedValueSet>
    <enumeratedValueSet variable="rewire-prob"><value value="0.1"/></enumeratedValueSet>
    <enumeratedValueSet variable="p"><value value="0.03"/></enumeratedValueSet>
    <enumeratedValueSet variable="q"><value value="0.4"/></enumeratedValueSet>
    <enumeratedValueSet variable="policy"><value value="&quot;None&quot;"/></enumeratedValueSet>
    <enumeratedValueSet variable="seed-strategy"><value value="&quot;None&quot;"/></enumeratedValueSet>
    <enumeratedValueSet variable="num-seeds"><value value="10"/></enumeratedValueSet>
    <enumeratedValueSet variable="show-links?"><value value="false"/></enumeratedValueSet>
    <enumeratedValueSet variable="heterogeneous?"><value value="false"/></enumeratedValueSet>
  </experiment>
  <experiment name="E2 Advertising effect (vary p)" repetitions="20" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <exitCondition>all-adopted?</exitCondition>
    <metric>time-to-50</metric>
    <metric>peak-tick</metric>
    <metric>ticks</metric>
    <enumeratedValueSet variable="num-agents"><value value="1000"/></enumeratedValueSet>
    <enumeratedValueSet variable="network-type"><value value="&quot;Small-world&quot;"/></enumeratedValueSet>
    <enumeratedValueSet variable="avg-links"><value value="5"/></enumeratedValueSet>
    <enumeratedValueSet variable="rewire-prob"><value value="0.1"/></enumeratedValueSet>
    <steppedValueSet variable="p" first="0.01" step="0.01" last="0.2"/>
    <enumeratedValueSet variable="q"><value value="0.4"/></enumeratedValueSet>
    <enumeratedValueSet variable="policy"><value value="&quot;None&quot;"/></enumeratedValueSet>
    <enumeratedValueSet variable="seed-strategy"><value value="&quot;None&quot;"/></enumeratedValueSet>
    <enumeratedValueSet variable="num-seeds"><value value="10"/></enumeratedValueSet>
    <enumeratedValueSet variable="show-links?"><value value="false"/></enumeratedValueSet>
    <enumeratedValueSet variable="heterogeneous?"><value value="false"/></enumeratedValueSet>
  </experiment>
  <experiment name="E3 Word-of-mouth effect (vary q)" repetitions="20" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <exitCondition>all-adopted?</exitCondition>
    <metric>time-to-50</metric>
    <metric>peak-tick</metric>
    <metric>ticks</metric>
    <enumeratedValueSet variable="num-agents"><value value="1000"/></enumeratedValueSet>
    <enumeratedValueSet variable="network-type"><value value="&quot;Small-world&quot;"/></enumeratedValueSet>
    <enumeratedValueSet variable="avg-links"><value value="5"/></enumeratedValueSet>
    <enumeratedValueSet variable="rewire-prob"><value value="0.1"/></enumeratedValueSet>
    <enumeratedValueSet variable="p"><value value="0.03"/></enumeratedValueSet>
    <steppedValueSet variable="q" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="policy"><value value="&quot;None&quot;"/></enumeratedValueSet>
    <enumeratedValueSet variable="seed-strategy"><value value="&quot;None&quot;"/></enumeratedValueSet>
    <enumeratedValueSet variable="num-seeds"><value value="10"/></enumeratedValueSet>
    <enumeratedValueSet variable="show-links?"><value value="false"/></enumeratedValueSet>
    <enumeratedValueSet variable="heterogeneous?"><value value="false"/></enumeratedValueSet>
  </experiment>
  <experiment name="E4 Connectivity effect (vary n)" repetitions="20" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <exitCondition>all-adopted?</exitCondition>
    <metric>time-to-50</metric>
    <metric>peak-tick</metric>
    <metric>ticks</metric>
    <enumeratedValueSet variable="num-agents"><value value="1000"/></enumeratedValueSet>
    <enumeratedValueSet variable="network-type"><value value="&quot;Small-world&quot;"/></enumeratedValueSet>
    <steppedValueSet variable="avg-links" first="1" step="1" last="30"/>
    <enumeratedValueSet variable="rewire-prob"><value value="0.1"/></enumeratedValueSet>
    <enumeratedValueSet variable="p"><value value="0.03"/></enumeratedValueSet>
    <enumeratedValueSet variable="q"><value value="0.4"/></enumeratedValueSet>
    <enumeratedValueSet variable="policy"><value value="&quot;None&quot;"/></enumeratedValueSet>
    <enumeratedValueSet variable="seed-strategy"><value value="&quot;None&quot;"/></enumeratedValueSet>
    <enumeratedValueSet variable="num-seeds"><value value="10"/></enumeratedValueSet>
    <enumeratedValueSet variable="show-links?"><value value="false"/></enumeratedValueSet>
    <enumeratedValueSet variable="heterogeneous?"><value value="false"/></enumeratedValueSet>
  </experiment>
  <experiment name="E5 Network structure" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <exitCondition>all-adopted?</exitCondition>
    <metric>time-to-50</metric>
    <metric>peak-tick</metric>
    <metric>ticks</metric>
    <enumeratedValueSet variable="num-agents"><value value="1000"/></enumeratedValueSet>
    <enumeratedValueSet variable="network-type"><value value="&quot;Small-world&quot;"/><value value="&quot;Random&quot;"/><value value="&quot;Scale-free (influencers)&quot;"/><value value="&quot;Fully mixed (classical Bass)&quot;"/></enumeratedValueSet>
    <enumeratedValueSet variable="avg-links"><value value="5"/></enumeratedValueSet>
    <enumeratedValueSet variable="rewire-prob"><value value="0.1"/></enumeratedValueSet>
    <enumeratedValueSet variable="p"><value value="0.03"/></enumeratedValueSet>
    <enumeratedValueSet variable="q"><value value="0.4"/></enumeratedValueSet>
    <enumeratedValueSet variable="policy"><value value="&quot;None&quot;"/></enumeratedValueSet>
    <enumeratedValueSet variable="seed-strategy"><value value="&quot;None&quot;"/></enumeratedValueSet>
    <enumeratedValueSet variable="num-seeds"><value value="10"/></enumeratedValueSet>
    <enumeratedValueSet variable="show-links?"><value value="false"/></enumeratedValueSet>
    <enumeratedValueSet variable="heterogeneous?"><value value="false"/></enumeratedValueSet>
  </experiment>
  <experiment name="E6 Policy comparison" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <exitCondition>all-adopted?</exitCondition>
    <metric>time-to-50</metric>
    <metric>peak-tick</metric>
    <metric>ticks</metric>
    <enumeratedValueSet variable="num-agents"><value value="1000"/></enumeratedValueSet>
    <enumeratedValueSet variable="network-type"><value value="&quot;Small-world&quot;"/></enumeratedValueSet>
    <enumeratedValueSet variable="avg-links"><value value="5"/></enumeratedValueSet>
    <enumeratedValueSet variable="rewire-prob"><value value="0.1"/></enumeratedValueSet>
    <enumeratedValueSet variable="p"><value value="0.03"/></enumeratedValueSet>
    <enumeratedValueSet variable="q"><value value="0.4"/></enumeratedValueSet>
    <enumeratedValueSet variable="policy"><value value="&quot;None&quot;"/><value value="&quot;Advertising campaign (p x3)&quot;"/><value value="&quot;Referral cashback (q x2)&quot;"/><value value="&quot;Ads + cashback&quot;"/></enumeratedValueSet>
    <enumeratedValueSet variable="seed-strategy"><value value="&quot;None&quot;"/></enumeratedValueSet>
    <enumeratedValueSet variable="num-seeds"><value value="10"/></enumeratedValueSet>
    <enumeratedValueSet variable="show-links?"><value value="false"/></enumeratedValueSet>
    <enumeratedValueSet variable="heterogeneous?"><value value="false"/></enumeratedValueSet>
  </experiment>
  <experiment name="E7 Seeding: random vs influencers" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <exitCondition>all-adopted?</exitCondition>
    <metric>time-to-50</metric>
    <metric>peak-tick</metric>
    <metric>ticks</metric>
    <enumeratedValueSet variable="num-agents"><value value="1000"/></enumeratedValueSet>
    <enumeratedValueSet variable="network-type"><value value="&quot;Scale-free (influencers)&quot;"/></enumeratedValueSet>
    <enumeratedValueSet variable="avg-links"><value value="5"/></enumeratedValueSet>
    <enumeratedValueSet variable="rewire-prob"><value value="0.1"/></enumeratedValueSet>
    <enumeratedValueSet variable="p"><value value="0.005"/></enumeratedValueSet>
    <enumeratedValueSet variable="q"><value value="0.4"/></enumeratedValueSet>
    <enumeratedValueSet variable="policy"><value value="&quot;None&quot;"/></enumeratedValueSet>
    <enumeratedValueSet variable="seed-strategy"><value value="&quot;None&quot;"/><value value="&quot;Random people&quot;"/><value value="&quot;Top influencers&quot;"/></enumeratedValueSet>
    <enumeratedValueSet variable="num-seeds"><value value="10"/></enumeratedValueSet>
    <enumeratedValueSet variable="show-links?"><value value="false"/></enumeratedValueSet>
    <enumeratedValueSet variable="heterogeneous?"><value value="false"/></enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
