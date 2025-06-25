breed [ users user ]
directed-link-breed [ follows-links follows-link ]

globals [
  total-users
  avg-followers
  avg-following
  isolated-users
  avg-hate-core
  min-hate-core
  max-hate-core
  total-blocks
  posts-this-tick
  post-freq-blue
  post-freq-green
  post-freq-yellow
  post-freq-orange
  post-freq-red
]

users-own [
   hate-core            ; how much hate this person has

   followers            ; who is following this user (it has to be a list)
   following            ; who this user is following (it has to be a list)
   blocked              ; who this user is blocking (it has to be a list)
   post-freq            ; determines how much this user posts (0 = less chance to post, 10 = more chance to post)
   birth-tick           ; set tick when he joyned

]



to setup-users
  create-users initial-users [
    setxy random-xcor random-ycor                    ; set users in any place of the map
    set size 1                                      ; set size of the users
    set shape "person"                               ; set shape of the turtles to person

    set hate-core random-float 10
    set followers []
    set following []
    set blocked []
    set post-freq random-float 10

    set-hate-color
    set birth-tick ticks
  ]
end

to link-usuarios
  ask users [
    let proximos other users in-radius user-radius-link-follow ; link length
    let num-conexoes random 3 ; link count

    if any? proximos [
      let alguns-proximos n-of min (list num-conexoes count proximos) proximos

      foreach sort alguns-proximos [
        follower ->
          if not [follows-link-neighbor? myself] of follower [
            create-follows-link-to follower
            set following lput follower following
            ask follower [
              set followers lput myself followers
            ]
          ]
      ]
    ]
  ]
end

to user-post [poster]
  ask poster [
    ; color of who posted
    if post-colors [set color violet]

    foreach followers [
      follower ->

        ask follower [

          let influence ([hate-core] of poster - hate-core) * hate-core-rate  ; % of diferente bettewen poster hate-core and receiver hate-core
          set hate-core hate-core + influence

          if hate-core > 10 [ set hate-core 10 ]
          if hate-core < 0 [ set hate-core 0 ]

          ; color of who recieved the post
          if post-colors [set color pink]

          ; chance to block poster
          block-user self poster
        ]
      ]
  ]
end

to set-hate-color
  ifelse hate-core >= 8.0 [
    set color red
  ] [
    ifelse hate-core >= 6.0 [
      set color orange
    ] [
      ifelse hate-core >= 4.0 [
        set color yellow
      ] [
        ifelse hate-core >= 2.0 [
          set color green
        ] [
          set color blue
        ]
      ]
    ]
  ]
end

to remove-isolated-users
  ask users with [ (length following = 0) and (length followers = 0) and (ticks - birth-tick) >= 100] [
    die
  ]
end

to follow-user [follower followed]
  ask follower [
    if (follower != followed) and (not member? followed following) and (distance followed <= user-radius-link-follow) and (not member? followed blocked) and (not member? follower [blocked] of followed) and ((ticks - [birth-tick] of followed) < max-user-tick-to-follow)[
      create-follows-link-to followed
      set following lput followed following

      ask followed [
        set followers lput follower followers
      ]
    ]
  ]
end

to follow-behavior
  ask users [
    if random-float 100 <= chance-to-follow [  ; % of chance to follow
      let possible-follow other users with [not member? self followers and distance myself <= user-radius-link-follow]
      if any? possible-follow [
        let chosen one-of possible-follow
        follow-user self chosen
      ]
    ]
  ]
end

to block-user [receiver poster]
  let hate-difference abs(hate-core - [hate-core] of poster)
  if (hate-difference >= (hate-core * hate-difference-to-block)) [
    if random-float 100 <= chance-to-block [ ; 50% chance of blocking
      ; add to blocked list
      set blocked lput poster blocked

      ; remove follow
      if member? poster following [
        set following remove poster following
        ask poster [
          set followers remove receiver followers
        ]
        ; remove link
        ask follows-link-with poster [
          die
        ]
      ]
    ]
  ]
end

to add-new-users
  let current-users count users

  if current-users < max-users [
    let users-to-add random 3 + 1 ;

    let available-slots max-users - current-users
    set users-to-add min (list users-to-add available-slots)

    create-users users-to-add [
      let try 0
      while [any? other users in-radius 0.5 and try < 100] [
        setxy random-xcor random-ycor
        set try try + 1
      ]

      ifelse any? other users in-radius 0.5 [
        die
      ]
      [
        set size 1
        set shape "person"
        set hate-core random-float 10
        set followers []
        set following []
        set blocked []
        set post-freq random-float 10
        set birth-tick ticks
        set-hate-color
      ]
    ]
  ]
end

to remove-old-users
  ask users [
    let user-age ticks - birth-tick
    if user-age >= max-age-user [
      if random-float 100 < chance-to-delete [ ; 5% de chance
        ; remove followers
        foreach followers [
          follower ->
          ask follower [
            set following remove myself following
          ]
        ]

        ; remove follows
        foreach following [
          followed ->
          ask followed [
            set followers remove myself followers
          ]
        ]

        ; remove links
        ask follows-link-neighbors [
          ask follows-link-with myself [
            die
          ]
        ]

        ; remove user
        die
      ]
    ]
  ]
end

to update-post-freq-by-color
  set post-freq-blue mean-post-freq-of-color blue
  set post-freq-green mean-post-freq-of-color green
  set post-freq-yellow mean-post-freq-of-color yellow
  set post-freq-orange mean-post-freq-of-color orange
  set post-freq-red mean-post-freq-of-color red
end

to add-good-guy
  create-users 1 [
    let try 0
    while [any? other users in-radius 0.5 and try < 100] [
      setxy random-xcor random-ycor
      set try try + 1
    ]

    ifelse any? other users in-radius 0.5 [
      die
    ]
    [
      set size 1
      set shape "person"
      set hate-core 0
      set followers []
      set following []
      set blocked []
      set post-freq 10
      set birth-tick ticks
      set-hate-color

      let proximos other users in-radius user-radius-link-follow
      let num-conexoes random 3 + 1 ;; conecta com até 3 usuários aleatórios

      if any? proximos [
        let alguns-proximos n-of min (list num-conexoes count proximos) proximos

        ask n-of min (list num-conexoes count proximos) proximos [
          create-follows-link-from myself
          set followers lput myself followers
          ask myself [
            set following lput myself following
          ]
        ]
      ]
      ask proximos [
        if not member? myself following and not member? myself blocked and not member? self [blocked] of myself [
          create-follows-link-to myself
          set following lput myself following
          ask myself [
            set followers lput myself followers
          ]
        ]
      ]
    ]
  ]
end

to add-chaos-agent
  create-users 1 [
    let try 0
    while [any? other users in-radius 0.5 and try < 100] [
      setxy random-xcor random-ycor
      set try try + 1
    ]

    ifelse any? other users in-radius 0.5 [
      die
    ]
    [
      set size 1
      set shape "person"
      set hate-core 10
      set followers []
      set following []
      set blocked []
      set post-freq 10
      set birth-tick ticks
      set-hate-color

      let proximos other users in-radius user-radius-link-follow
      let num-conexoes random 3 + 1 ;; conecta com até 3 usuários aleatórios

      if any? proximos [
        let alguns-proximos n-of min (list num-conexoes count proximos) proximos

        ask n-of min (list num-conexoes count proximos) proximos [
          create-follows-link-from myself
          set followers lput myself followers
          ask myself [
            set following lput myself following
          ]
        ]
      ]
      ask proximos [
        if not member? myself following and not member? myself blocked and not member? self [blocked] of myself [
          create-follows-link-to myself
          set following lput myself following
          ask myself [
            set followers lput myself followers
          ]
        ]
      ]
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;; METRICS ;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to report-metrics
  set total-users count users

  ifelse total-users > 0 [
    set avg-followers mean [length followers] of users
    set avg-following mean [length following] of users
    set isolated-users count users with [length followers = 0 and length following = 0]
    set avg-hate-core mean [hate-core] of users
    set min-hate-core min [hate-core] of users
    set max-hate-core max [hate-core] of users
    set total-blocks sum [length blocked] of users
  ] [
    set avg-followers 0
    set avg-following 0
    set isolated-users 0
    set avg-hate-core 0
    set min-hate-core 0
    set max-hate-core 0
    set total-blocks 0
  ]

  ; contar posts feitos no tick atual
  set posts-this-tick 0
  ask users [
    if post-freq > random-float 10 [
      set posts-this-tick posts-this-tick + 1
    ]
  ]

  show (word "Tick: " ticks)
  show (word "Total users: " total-users)
  show (word "Avg followers: " precision avg-followers 2)
  show (word "Avg following: " precision avg-following 2)
  show (word "Isolated users: " isolated-users)
  show (word "Hate-core (avg/min/max): " precision avg-hate-core 2 " / " precision min-hate-core 2 " / " precision max-hate-core 2)
  show (word "Total blocks: " total-blocks)
  show (word "Posts this tick: " posts-this-tick)
  show (word "====================================")
end

to-report mean-post-freq-of-color [cor]
  let agents users with [color = cor]
  ifelse any? agents [
    report mean [post-freq] of agents
  ] [
    report 0
  ]
end

to-report report-avg-hate-core
  report avg-hate-core
end

to-report report-total-users
  report total-users
end

to-report report-avg-followers
  report avg-followers
end

to-report report-avg-following
  report avg-following
end

to-report report-total-blocks
  report total-blocks
end

to-report report-posts-this-tick
  report posts-this-tick
end

to-report report-isolated-users
  report isolated-users
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go

  ; users post something
  ask users [
    if post-freq > random-float 10[
      user-post self
    ]
  ]

  ; add new users
  add-new-users
  update-post-freq-by-color

  ; follow new users
  follow-behavior

  tick
  ; adjust users hate colors
  ask users [
    set-hate-color
  ]

  ; remove users without links
  remove-isolated-users
  ; remove users with high tick with % chance
  remove-old-users
  report-metrics
  tick
end


to setup
  clear-all
  reset-ticks
  setup-users
  link-usuarios
  layout-spring users follows-links 1 5 1
end
@#$#@#$#@
GRAPHICS-WINDOW
305
20
973
689
-1
-1
20.0
1
10
1
1
1
0
0
0
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
81
138
145
171
Setup
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

BUTTON
163
138
226
171
Go
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

SLIDER
55
224
260
257
max-user-tick-to-follow
max-user-tick-to-follow
0
1000
100.0
1
1
ticks
HORIZONTAL

SLIDER
54
263
262
296
user-radius-link-follow
user-radius-link-follow
1
300
10.0
1
1
radius
HORIZONTAL

SLIDER
69
300
241
333
chance-to-follow
chance-to-follow
1
100
6.0
1
1
%
HORIZONTAL

SLIDER
68
337
240
370
chance-to-block
chance-to-block
1
100
37.0
1
1
%
HORIZONTAL

SLIDER
67
372
249
405
hate-difference-to-block
hate-difference-to-block
0
1
0.2
0.1
1
NIL
HORIZONTAL

SLIDER
70
408
242
441
hate-core-rate
hate-core-rate
0.1
1
0.4
0.1
1
NIL
HORIZONTAL

SLIDER
70
49
242
82
initial-users
initial-users
20
500
29.0
1
1
users
HORIZONTAL

SWITCH
94
97
211
130
post-colors
post-colors
1
1
-1000

SLIDER
70
10
242
43
max-users
max-users
50
500
113.0
1
1
users
HORIZONTAL

SLIDER
70
446
242
479
max-age-user
max-age-user
50
5000
1595.0
1
1
tick
HORIZONTAL

SLIDER
70
485
242
518
chance-to-delete
chance-to-delete
1
100
2.0
1
1
%
HORIZONTAL

PLOT
988
15
1315
298
hate-core
Ticks
People
0.0
250.0
0.0
350.0
true
true
"set-plot-y-range 0 (max-users)" ""
PENS
"10-8" 1.0 0 -5298144 true "" "plot count turtles with [color = red]"
"8-6" 1.0 0 -955883 true "" "plot count turtles with [color = orange]"
"6-4" 1.0 0 -1184463 true "" "plot count turtles with [color = yellow]"
"4-2" 1.0 0 -13840069 true "" "plot count turtles with [color = green]"
"2-0" 1.0 0 -13345367 true "" "plot count turtles with [color = blue]"

MONITOR
1137
509
1201
554
avg-hate
report-avg-hate-core
5
1
11

MONITOR
1000
509
1075
554
Total users
report-total-users
5
1
11

MONITOR
999
556
1082
601
Avg. followers
report-avg-followers
5
1
11

MONITOR
999
603
1082
648
Avg. following
report-avg-following
5
1
11

MONITOR
1000
649
1076
694
Total blocks
report-total-blocks
5
1
11

MONITOR
1136
556
1225
601
Posts this tick
report-posts-this-tick
5
1
11

MONITOR
1137
604
1227
649
Isolated users
report-isolated-users
5
1
11

PLOT
992
305
1276
504
freq-post
Ticks
Freq
0.0
250.0
0.0
10.0
true
false
"" ""
PENS
"10-08" 1.0 0 -2674135 true "" "plot post-freq-red"
"8-6" 1.0 0 -817084 true "" "plot post-freq-orange"
"6-4" 1.0 0 -987046 true "" "plot post-freq-yellow"
"4-2" 1.0 0 -11085214 true "" "plot post-freq-green"
"2-0" 1.0 0 -13345367 true "" "plot post-freq-blue"

BUTTON
39
181
148
214
Add good guy
add-good-guy
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
155
181
272
214
Add chaos agent
add-chaos-agent
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
NetLogo 6.4.0
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
