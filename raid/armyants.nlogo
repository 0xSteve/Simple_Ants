globals[screen-area vol-food out-pher in-pher xhome yhome clock nest-food sqrt2 found-food snap-to-home]
breed [foods food]
breed [ants ant]

ants-own [hasfood? move? hasleft? ishome? num-dead]
foods-own [density]
patches-own [phermone]

to setup
  clear-all
  reset-ticks
  ask patches
  [
    set pcolor brown
  ]
  set-default-shape ants "bug" ;; really no reason to do this considering how zoomed out we are. might just remove this.
  set-default-shape foods "circle" ;; food can be a circle, right?
  set screen-area (max-pxcor * max-pycor * 2) ;;times 2 if bottom center, times 4 if middle
  set out-pher 1000
  set in-pher 300
  set xhome 0
  set yhome 5
  set clock 0
  set snap-to-home 5
  set found-food 0
  set nest-food 0
  set sqrt2 1.41421356237
  ;;setup-patches
  setup-food
end

to step
  setup-ants
  ant-move
  evaporate
end

to clear
  clear-all
end

to test
  ask ants
  [
    pick-a-patch
  ]
end

to go
  if clock < it-max
  [
    set clock (clock + 1)
    step
  ]
  tick
end

to setup-patches
  ;;probably best to avoid this because it slows things down.
  ask patches [
    set pcolor brown
  ]
end

to setup-food
    let rand 0

    set vol-food (screen-area * (amount-food / 100)) ;; spawn food nodes proportional to the percentage of space
    create-foods (vol-food)  ;; make the food
    ask foods
      [
        set density food-density
      ]
    ask foods
      [
      ;;Do this eventhough 0,0 is at the bottom edge?
      ;;Just quarter up the food so it looks good xD
        set rand random 100
        ifelse rand <= 25
            [ set xcor (random world-width)
              set ycor (random world-height)
            ]
            [ ifelse (rand > 25) and (rand <= 50)
                [ set xcor (random world-width) * -1
                  set ycor (random world-height)
                ]
                [ ifelse (rand > 50) and (rand <= 75)
                    [ set xcor (random world-width) * -1
                      set Ycor (random world-height) * -1
                    ]

                    [ set xcor (random world-width)
                      set Ycor (random world-height) * -1
                    ]
                ]
            ]
       set color green    ;; Makes sure all food is green, pretend the ants are vegan.
     ]
end

to setup-ants
  ;;All ants start at the bivouac
  ;; maybe i should kill ants that refuse to leave the nest?
  ask ants
  [
    if (not hasleft?)
    [
      ;;maybe not for now...
      ;;die
      ;;set num-dead (num-dead + 1)
    ]
  ]
  create-ants antspinterval
  [
    set hasfood? false
    set hasleft? false
    set ishome? true
    set heading 0
    ;;have to send them home
    set color black
    setxy xhome yhome
    set move? false
  ]
end

to ant-move
  ask ants
  [
    ifelse ishome?
    [;;currently at home, time to make a move.
      set color black
      set heading 0
      set ishome? false
      set hasleft? true
      if hasfood?
      [
        set hasfood? false
        set nest-food (nest-food + 1)
      ]
    ]
    [;;else;;
      ifelse (abs(xcor) > max-pxcor - 1.5) or (abs(ycor) > max-pycor - 1.5) ;;ant is off the world.
      [
        die
      ]
      [;;else;;
        ifelse hasfood?
        [
          ;;if the ant has food send it home!
          set color white
          ;;If sufficiently close to the nest, become home.
          if distancexy-nowrap xhome yhome < snap-to-home
                  [
                    set xCor xhome
                    set yCor yhome
                    set ishome? true
                  ]
          ;;pick a patch facing the home base.
          pick-a-patch-returned
        ]
        [;;else;;
          find-food
        ]
      ]
    ]
  ]
end

to lay-phermone
  ifelse (hasleft?)
  [
    if (phermone < out-pher)
    [
      set phermone (phermone + 1)
    ]
  ]
  [;;else;;
    if (phermone < in-pher)
    [
      set phermone (phermone + 10)
    ]
  ]
end

to-report phermones
  report [phermone] of patch-at dx dy
end
to-report ants-at-pos
  report count ants-at dx dy
end

to find-food
  ifelse (count foods-here > 0)
  [
    ;;there is food.
    set hasfood? true
    set found-food (found-food + 1)
    ask foods-here
    [
      set density (density - 1)
      if (density <= 0)
      [
        ;;no more food!
        die
      ]
    ]
    ;;turn around
    set heading 180
    ;;go home
    pick-a-patch-returned
  ]
  [;;else;;
    pick-a-patch
  ]
end

to pick-a-patch
  ;;the move after leaving home

  ;;need some hyperbolic tan
  let l_l 0
  let l_r 0
  let z 0
  let tanh 0
  let P_m 0
  let x ( (random 100) / 100)
  let p_l 0
  let p_r 0

  ;;okay so i want the scent to the left, and to the right. if i understand this correctly, then...
  lt 45 ;; turn left 45 degrees from normal
  set l_l phermones
  rt 90 ;; turn right 45 degrees from normal
  set l_r phermones
  lt 45 ;;return to normal
  set z ( ( (l_l + l_r) / 100) - 1)
  set tanh ( ( exp(2 * z) - 1 ) / ( exp(2 * z) + 1 ) )
  ;; Does it move?
  set P_m ( 0.5 * (tanh + 1) )

  if ( x < P_m)
  [
    set move? true
    set hasleft? true
    lay-phermone
  ]

  ;;maybe break this bit into two just for a bit...

  if (move?)
  [
    ;;get p_l
    set p_l ( ((k + l_l) ^ n) / ( (k + l_l) ^ n + (k + l_r) ^ n ) )
    set p_r ( 1 - p_l )

    ;; roll the dice again to see which direction we travel
    set x ( (random 100) / 100)
    ifelse (x < p_l)
    [
      ;;turn left;;
      set heading 0 ;;reset heading
      lt 45
      ifelse (ants-at-pos < antsperpatch)
      [
        jump sqrt2
        set heading 0
      ]
      [;;else;;
        rt 90
        ifelse (ants-at-pos < antsperpatch)
        [
          jump sqrt2
          set heading 0
        ]
        [
          ;;can't move!
        ]
      ]
    ]
    [
      ;;turn right;;
      set heading 0 ;;reset heading
      rt 45
      ifelse (ants-at-pos < antsperpatch)
      [
        jump sqrt2
        set heading 0
      ]
      [;;else;;
        lt 90
        ifelse (ants-at-pos < antsperpatch)
        [
          jump sqrt2
          set heading 0
        ]
        [
          ;;can't move
        ]
      ]
    ]
  ]
  set move? false
end
to pick-a-patch-returned
  ;;should be a bit better than test it every time to see if it's facing home.
  ;;need some hyperbolic tan
  let l_l 0
  let l_r 0
  let z 0
  let tanh 0
  let P_m 0
  let x ( (random 100) / 100)
  let p_l 0
  let p_r 0

  ;;i should set heading to 180 and rotate, but i dont feel like thinking
  set heading 225
  set l_l phermones
  set heading 135
  set l_r phermones
  set heading 180 ;;return to normal
  set z ( ( (l_l + l_r) / 100) - 1)
  set tanh ( ( exp(2 * z) - 1 ) / ( exp(2 * z) + 1 ) )
  ;; Does it move?
  set P_m ( 0.5 * (tanh + 1) )

  ;;if they are returning home they should never question whether or not to move.
  ;;but perhaps they should question whether or not to lay a phermone trail?
  if (x < P_m)
  [
    lay-phermone
  ]
  set move? true
  set hasleft? true

  ;;get p_l
  set p_l ( ((k + l_l) ^ n) / ( (k + l_l) ^ n + (k + l_r) ^ n ) )
  set p_r ( 1 - p_l )

  ;;The ants returning seem to be very far from the formation. perhaps if there is some bias?
  let threshold 5
  if (l_l < threshold)
  [
    set p_l 0
  ]
  if (l_r < threshold)
  [
    set p_r 0
  ]
  ;;they can go astray here if both probabilities are zero. have to adjust here.
  ;;I found a similar ants example online and that example uses a bias and a correction.
  ;;Talk to prof about this.
  ifelse (p_l + p_r = 0) and (xCor < 0)
  [
    ;;forcing a jump like this might be illegal? talk to the prof.
    set heading 135
    jump sqrt2
    set heading 180
  ]
  [
    ifelse (p_l + p_r = 0) and (xCor > 0)
    [
      set heading 225
      jump sqrt2
      set heading 180
    ]
    [
      ifelse (p_l + p_r = 0)
      [
        ;;is this even a legal move? I'm not sure, but it at least goes towards the home.
        set heading 180
        jump 0
      ]
      [
        set p_l (p_l / (p_l + p_r) )
        set p_r (p_r / (p_l + p_r) )
      ]
    ]
  ]
  ;;the above corrects for outside of threshold. Now for regular movement...
  ifelse (x < p_l)
  [
    ;;turn left;;
    set heading 225
    ifelse (ants-at-pos < antsperpatch)
    [
      jump sqrt2
      set heading 180
    ]
    [;;else;;
      set heading 135
      ifelse (ants-at-pos < antsperpatch)
      [
        jump sqrt2
        set heading 180
      ]
      [
        ;;can't move!
      ]
    ]
  ]
  [
    ;;turn right;;
    set heading 180 ;;reset heading
    set heading 135
    ifelse (ants-at-pos < antsperpatch)
    [
      jump sqrt2
      set heading 180
    ]
    [;;else;;
      set heading 225
      ifelse (ants-at-pos < antsperpatch)
      [
        jump sqrt2
        set heading 180
      ]
      [
        ;;can't move!
      ]
    ]
  ]
  set move? false
end

to evaporate

  ask patches
    [
      if (phermone < 0)
      [
        set phermone 0
      ]

      if (phermone > 0)
        [
          set phermone (phermone * ((100 - evap) / 100))
        ]
    ]

end
@#$#@#$#@
GRAPHICS-WINDOW
429
10
800
622
-1
-1
3.0
1
10
1
1
1
0
1
1
1
-60
60
0
200
1
1
1
ticks
30.0

BUTTON
275
10
348
43
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
218
56
390
89
amount-food
amount-food
0
100
75.0
1
1
NIL
HORIZONTAL

BUTTON
357
10
420
43
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
199
10
266
43
NIL
clear
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
222
396
394
429
it-max
it-max
1
2000
1200.0
200
1
NIL
HORIZONTAL

SLIDER
218
162
390
195
k
k
1
100
5.0
1
1
NIL
HORIZONTAL

SLIDER
219
203
391
236
n
n
1
100
2.0
1
1
NIL
HORIZONTAL

SLIDER
220
245
392
278
evap
evap
0
100
5.0
1
1
NIL
HORIZONTAL

SLIDER
222
353
394
386
antspinterval
antspinterval
1
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
221
309
393
342
antsperpatch
antsperpatch
10
100
25.0
5
1
NIL
HORIZONTAL

SLIDER
218
99
390
132
food-density
food-density
1
100
35.0
1
1
NIL
HORIZONTAL

PLOT
819
10
1366
413
Food Found Vs. Food Returned to Nest
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Food Found" 1.0 0 -16777216 true "" "if(ploton?) [plotxy clock found-food]"
"Food Returned" 1.0 0 -7500403 true "" "if(ploton?) [plotxy clock nest-food]"

SWITCH
819
421
929
454
ploton?
ploton?
1
1
-1000

@#$#@#$#@
## WHAT IS IT?

A simple incarnation of the Army Ants Raiding problem.

## HOW IT WORKS

For this model there are two breeds of agents: foods, and ants. 

The food agents are scattered randomly around the environment and are allowed to overlap each other in space. These food agents have a property called, density, which defines how much food can be harvested by an ant. It is assumed that each ant can carry 1 food item and thus the density is an integer value.

The ant agents each originate from a common nest and move away from the nest with probability either to the left or right along a diagonal path, or not at all. The ant lays a pheromone trail by depositing pheromone at each patch it encounters. 
If the ant finds a food item, it turns around and moves with probability 1 in the opposite direction. Again the movement is left or right along a diagonal path. However, this time the ant will bias it's movement to focus on patches with high pheromone concentration. Increasing probability that it will successfully return food to the nest. Finally, if the ant is sufficiently close to the nest it will return the food. If the ant contacts a boundary it will die.

## HOW TO USE IT

1) To use it without adjusting default values simply click the setup button and then press the go button.

2) To restart the simulation click the clear button and then repeat step (1).

The sliders control different environment or model parameters. N and K sliders represent the user defined parameters of the probabilistic ant model.

Sliders:
amount-food -> Defines the proportion of food on the map relative to the total number of patches.
food-density -> Defines the amount of food stored in each food agent.
antsperpatch -> Defines the maximum number of ants allowed to occupy a patch.
evap -> Determines how rapidly pheromone evaporates from a patch.
antsperinterval -> Defines the number of ants born from the nest for each unit of time.
it-max -> Defines the maximum number of iterations before the algorithm terminates.

Swithces:
ploton? -> Control whether or not the plot will output plot data. Turn this off if Netlogo is choking your computer.

## THINGS TO NOTICE

Notice the shape of the raid front, and notice how the threshold forces the returning ants to envelope the raiding ants in a way which is similar to what one sees in nature.

## THINGS TO TRY

I think the most interesting variables to play with are N and K to change the shape of the raid.

Another interesting thing to do is change the limits of ants being born and allowed on a patch.

## EXTENDING THE MODEL
One thing that is partially ready is a hasleft? variable to kill ants that refuse to leave the nest within a certain number of moves.

Another possibility is to kill ants that stray on their way home, by limiting the number of no-pheromone patches they are allowed to walk on before dropping food.

And see what happens if we add multiple nest entrances/exists or different breeds of ant that will fight with each other.

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## ASSUMPTIONS
It is assumed that the ants share a common awareness of heading.
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

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
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
