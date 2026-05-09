extensions [palette matrix nw table]

globals [ soil-csv-header-written? species tree-set mate N Ni Nt1 Nt2 Nt3 Nt4 Nt5 Nt6 Nt7 Nt8 Nt9 Nt counter current-tick

          nearest-neighbor-threshold second-neighbor-threshold
          start? harvesting trimming fertilizing  soil-factor
          growth-rate-ilex  growth-rate-cana  growth-rate-an  growth-rate-la  growth-rate-pet  growth-rate-ar  growth-rate-gu
          growth-rate-toona  growth-rate-gr  growth-rate-ki
          growth-energy-uptake
          harvest-size         ; Minimum size for harvesting
          tree-trim-size       ; Minimum size for trimming
          tree-thin-size       ; Minimum size for thinning
          harvest-rate         ; Percentage of plant harvested
          harvest-amount       ; Amount ilex plants are reduced as harvest
          total-harvest        ; Total amount harvested over time
          minimum-viable-size  ; Minimum size for a plant to be manipulated
          harvest-trees        ; Amount trees are reduced as trimming which is a harvest
          thinned-amount       ; Amount of tree mass reduced by thinning
          et soil-multiplier-mate soil-multiplier-trees species-multipliers  soil-multiplier-increment convert-dry convert-SOM buffer-factor fertilizer-amount
  thiniter1?  thiniter2? thinned-count soil-multiplier soil-gain countert1 last-rebalance  previous-soil-energy soil-energy-improvement]

breed [ species0 ilex ]             ; ilex
breed [ species1 Toona ]            ; Toona
breed [ species2 Cana ]             ; Cañafístola
breed [ species3 La ]               ; Lapacho
breed [ species4 Pet ]              ; Petiribí
breed [ species5 An ]               ; Anchico
breed [ species6 Ar ]               ; Araucaria
breed [ species7 Gu]                ; Guatambú
breed [ species8 Gr ]               ; Grevillea
breed [ species9 Ki ]               ; Kiri

species0-own [ energy-ilex harvested-amount]
species1-own [ energy-Toona       soil-multiplier-Toona]
species2-own [ energy-Cañafístola soil-multiplier-Cañafístola]
species3-own [ energy-Lapacho     soil-multiplier-Lapacho]
species4-own [ energy-Petiribí    soil-multiplier-Petiribí]
species5-own [ energy-Anchico     soil-multiplier-Anchico]
species6-own [ energy-Araucaria   soil-multiplier-Araucaria]
species7-own [ energy-Guatambú    soil-multiplier-Guatambú]
species8-own [ energy-Grevillea   soil-multiplier-Grevillea]
species9-own [ energy-Kiri        soil-multiplier-Kiri]
turtles-own  [ energy-trees ]
patches-own  [ soil soil-energy  soil1 soil2 soil3 soil4 soil5 local-soil-factor]
links-own [ weight link-interaction-type
            weight-distance
            weight-shade
            weight-soil
            weight-combined
            neighbor-order  ; 1 for first neighbors, 2 for second neighbors
]

to setup
  clear-all
  resize-world 0 210 0 210
  set-patch-size 3
  set tree-set []                                                 ;; List of all trees
  set mate  []                                                    ;; List of all ilex plants
  set species []                                                  ;; List of all plants, ilex & trees
  set start? true
  set thiniter1? true
  set thiniter2? false
  set thinned-count 0

  set harvesting   [24 76 128 180 232 284 336 388 440 492 544]    ;; For efficiency, lists are given not computed; Harvest June 24
  set fertilizing  [40 92 144 196 248 300 352 404 456 508 560]    ;; Fertilizing October 40
  set trimming     [36 88 140 192 244 296 348 400 452 504 556]    ;; Trimming trees from September year 1 36

  ask patches  [
  set soil fertility                                              ;; the terrain (patches) variable soil takes the value of the chosen soil fertility starting point
  if 8000 <= fertility and fertility <= 10000                     ;; colors represent the starting soil fertility, chosen by the user, which is stored in soil types 1 to 5
    [ set pcolor    49
      set soil1 fertility ]
  if 6000 <= fertility and fertility <= 8000
    [ set pcolor    39
      set soil2 fertility ]
  if 4000 <= fertility and fertility <= 6000
    [ set pcolor    29
      set soil3 fertility ]
  if 2000 <= fertility and fertility <= 4000
    [ set pcolor    19
      set soil4 fertility ]
  if fertility <= 2000  [
      set pcolor  139
      set soil5 fertility ]
   ]
  set growth-rate-ilex  0.22
  set growth-rate-toona 0.64
  set growth-rate-cana  0.33
  set growth-rate-la    0.49
  set growth-rate-pet   0.44
  set growth-rate-an    0.32
  set growth-rate-ar    0.25
  set growth-rate-gu    0.56
  set growth-rate-gr    0.35
  set growth-rate-pet   0.44
  set growth-rate-ki    0.54
  set nearest-neighbor-threshold 7.5
  set second-neighbor-threshold  16.5

  let species-names ["Toona" "Cañafístola" "Lapacho" "Petiribí" "Anchico" "Araucaria" "Guatambú" "Grevillea" "Kiri"]
  foreach (range 1 10) [ i ->
    if i > 0 [  ; Skip species0 (ilex)
      let breed-name (word "species" i)
      let species-name item (i - 1) species-names
      ask (turtle-set runresult breed-name) [
        run (word "set soil-multiplier-" species-name " 0.05")  ; Small initial value
      ]
    ]
  ]
  set growth-energy-uptake 0
  set soil-multiplier-mate 0
  set soil-multiplier-trees 0
  set soil-multiplier 0
  set species-multipliers table:make
  set soil-multiplier-increment 0
  set soil-energy-improvement 1
  set convert-dry  0.12
  set convert-SOM  0.3
  set buffer-factor 0.12
  set fertilizer-amount 0
  set soil-gain 0
  set countert1 0
  set last-rebalance 0
  set previous-soil-energy 0
  set harvest-size 2.5                                            ;; only harvest plants size 2.5 or larger
  set tree-trim-size 3.2                                          ;; only trim trees size 3.2 or larger
  set tree-thin-size 9                                            ;; only thin trees size 9 or larger
  set harvest-rate harvest-intensity / 100                        ;; Harvest 34% of the plant
  set total-harvest 0
  set harvest-amount []
  set minimum-viable-size 0.25
  set harvest-trees 0
  set thinned-amount 0
  ask patches [ set local-soil-factor 1 ]

  let  n1 0                                                       ;; create the initial array of Species0, ilex plants, mate
   while [ n1 < 20]
         [let n2 0
          while [n2 < 20]
            [let x n1 * 10 + 10
             let y n2 * 10 + 10
             create-species0  1 [
                setxy  x  y
                set mate lput self mate
                set species lput self species
              ]
         set n2 n2 + 1
           ]
    set n1 n1 + 1
         ]
    ask species0 [set shape "plant"]
    ask species0 [set color 66]
    ask species0 [set size 3]
    set Ni  count species0                                        ;; Ni is the counter for the number of mate plants, number ilex
    print "number ilex"
    show Ni
    print "list ilex plants"
    show mate

  let species-data [                                              ;; each species will be placed at a determined x and y offsetset coordinates, with a color
    ["species1" 0    0  53]
    ["species2" 20   0  55]
    ["species3" 40   0  57]
    ["species4" 60   0  63]
    ["species5" 80   0  67]
    ["species6" 100  0 43]
    ["species7" 120  0 75]
    ["species8" 140  0 77]
    ["species9" 160  0 74]
  ]
  foreach species-data [ data ->
    let breed-name item 0 data
    let start-x item 1 data
    let start-y item 2 data
    let colour  item 3 data
    create-species breed-name start-x start-y colour
    create-species breed-name (start-x + 10) start-y colour
  ]
  foreach (range 1 10) [ i ->
    run (word "set Nt" i " count species" (i))
  ]
  set Nt (Nt1 + Nt2 + Nt3 + Nt4 + Nt5 + Nt6 + Nt7 + Nt8 + Nt9)    ;; Nt is the counter for the number of all trees of all species
  print "number trees"
  show Nt
  print "list tree set"
  show tree-set
  print "list of species"
  show species
  if idlabel?  [idLabel]
  initialize-soil-monitoring

  reset-ticks
end

to create-species [breed-name start-x start-y colour]
  let coordinates (n-values 21 [i -> list 5 (5 + i * 10)])
  foreach coordinates [ xy ->
    create-turtles 1 [
      set breed runresult breed-name
      setxy (item 0 xy + start-x) (item 1 xy + start-y)
      set shape "tree"
      set color colour
      set size 3
      set tree-set lput self tree-set
      set species lput self species
    ]
  ]
end

to-report get-species [k]
  report (word "species" k)
end

to-report get-growth-rate [k]
  let species-names ["ilex" "toona" "cana" "la" "pet" "an" "ar" "gu" "gr" "ki"]
  report (word "growth-rate-" (item k species-names))
end

to go
    time-account

    if w-network?  [create-weighted-network]
    if multi-network?  [create-multi-interaction-network]
    if w-matrix? and ticks mod 26 = 0   [ export-weighted-matrix-with-time  ]
    if w-matrix_xy? and ticks mod 26 = 0   [ export-weighted-matrix-with-coordinates ]
    set current-tick ticks

    nodeData
    linkData
    set-soil-factor
    energy-account

    if  ticks mod 16 = 0 [grow]
    if  ticks > 1 and ticks mod 26 = 0 [rebalance-soil]
    if ticks mod 26 = 0 [
    print "\nSoil Multiplier Status:"
    print soil-multiplier-sources
    ]

    foreach harvesting  [ x -> if ticks = x [harvest-ilex]]
    foreach harvesting  [ x -> if ticks = x [harvest-ilex-nearest-neighbors]]

    foreach fertilizing  [ x -> if ticks = x [fertilize]]
    foreach trimming    [ x -> if ticks = x [trim-trees]]
    if any? turtles with [size >= 12] [thinning1]
    if ticks > countert1 + 78 [thinning2]
    if ticks mod 16 = 0 [compete-shade]
    if  ticks > 1 and ticks mod 26 = 0 [decay-local-soil-factor]

    ask species0 [die-ilex]
    ask species1 [die-tree]
    tick
    if ticks >= 521 [ stop ]
end

to time-account
  set counter counter + 1
end

to idLabel
    ask turtles [
      set label who
      set label-color blue ]
end

to create-network                                                          ;; Define lists for species breeds and their corresponding link colors
  let tree-list (list species1 species2 species3 species4 species5 species6 species7 species8 species9)
  let colors-list (list 53 55 57 63 67 43 75 77 74)                        ;; Corresponding colors for links
  let tree-colors (map list tree-list colors-list)                         ;; Combine species and colors into pairs
  foreach tree-colors [ pair ->
      let sp first pair
      let colour last pair
      ask species0 [                                                       ;; Find the minimum distance to any turtle of the current species
      let min-dist min [distance myself] of sp                             ;; Find all turtles of the current species at this minimum distance
      let closest-tree sp with [distance myself = min-dist]                ;; Create a link with the closest turtles if within threshold distance
      ask closest-tree [
        if min-dist < 7.1 [
          create-link-with myself [
            set color colour
                     ]
                 ]
             ]
         ]
     ]
end

to test-neighbors-1
  ; Clear any existing links
  ask links [ die ]
  ; Define lists for species breeds and their corresponding link colors
  let tree-list (list species1 species2 species3 species4 species5 species6 species7 species8 species9)
  ; Loop through each tree species
  foreach tree-list [ sp ->
    ; For each ilex plant
    ask species0 [
      let ilex-plant self
      ; Find first neighbors
      let first-neighbors sp with [distance ilex-plant <= nearest-neighbor-threshold]
      ; Create just distance links for first neighbors
      ask first-neighbors [
        create-link-with ilex-plant [
          set link-interaction-type "distance-1-test"
          set label "1st-test"
          set weight 1
          set color red
          set thickness 0.2
        ]
      ]
    ]
  ]
  print (word "Test links 1st created: " count links with [link-interaction-type = "distance-1-test"])
end
to test-neighbors-2
  ; Clear any existing links
  ask links [ die ]
  ; Define lists for species breeds and their corresponding link colors
  let tree-list (list species1 species2 species3 species4 species5 species6 species7 species8 species9)
  ; Loop through each tree species
  foreach tree-list [ sp ->
    ; For each ilex plant
    ask species0 [
      let ilex-plant self
      ; Find second neighbors
      let second-neighbors sp with [distance ilex-plant > nearest-neighbor-threshold and
                                    distance ilex-plant < second-neighbor-threshold]
      ; Create just distance links for second neighbors
      ask second-neighbors [
        create-link-with ilex-plant [
          set link-interaction-type "distance-2-test"
          set label "2nd-test"
          set weight 0.5
          set color green
          set thickness 0.1
        ]
      ]
    ]
  ]
  print (word "Test links 2nd created: " count links with [link-interaction-type = "distance-2-test"])
end

; Add this to your code to check distance distributions
to check-neighbor-distances
  let first-neighbors 0
  let second-neighbors 0

  ask species0 [
    let ilex-plant self
    set first-neighbors first-neighbors + count turtles with [
      breed != species0 and
      distance ilex-plant <= nearest-neighbor-threshold
    ]
    set second-neighbors second-neighbors + count turtles with [
      breed != species0 and
      distance ilex-plant > nearest-neighbor-threshold and
      distance ilex-plant < second-neighbor-threshold
    ]
  ]
  print (word "Total first neighbors: " first-neighbors)
  print (word "Total second neighbors: " second-neighbors)

  ; Sample a few specific distances for verification
  print "\nSample distances:"
  ask one-of species0 [
    let ilex-plant self
    print "First neighbors:"
    ask up-to-n-of 10 (turtles with [breed != species0 and distance ilex-plant <= nearest-neighbor-threshold]) [
      print (word "  Distance: " distance ilex-plant ", Tree: " self)
    ]
    print "Second neighbors:"
    ask up-to-n-of 10 (turtles with [breed != species0 and
                                   distance ilex-plant > nearest-neighbor-threshold and
                                   distance ilex-plant < second-neighbor-threshold]) [
      print (word "  Distance: " distance ilex-plant ", Tree: " self)
    ]
  ]
end

to create-test-network-and-export
  ; Network creation and Adjacency Matrix export
  ; Clear any existing links
  ask links [ die ]

  ; Define lists for species breeds and their corresponding link colors
  let tree-list (list species1 species2 species3 species4 species5 species6 species7 species8 species9)

  ; Loop through each tree species
  foreach tree-list [ sp ->
    ; For each ilex plant
    ask species0 [
      let ilex-plant self

      ; Find first neighbors
      let first-neighbors sp with [distance ilex-plant <= nearest-neighbor-threshold]

      ; Create distance links for first neighbors
      ask first-neighbors [
        create-link-with ilex-plant [
          set link-interaction-type "distance-1-test"
          set label "1st"  ; Changed to "1st" for consistency with matrix export
          set weight 1
          set color red
          set thickness 0.2
        ]
      ]

      ; Find second neighbors
      let second-neighbors sp with [
        distance ilex-plant > nearest-neighbor-threshold and
        distance ilex-plant < second-neighbor-threshold
      ]

      ; Create distance links for second neighbors
      ask second-neighbors [
        create-link-with ilex-plant [
          set link-interaction-type "distance-2-test"
          set label "2nd"  ; Changed to "2nd" for consistency with matrix export
          set weight 0.5
          set color green
          set thickness 0.1
        ]
      ]
    ]
  ]

  ; Report on created links
  print (word "Test links 1st created: " count links with [link-interaction-type = "distance-1-test"])
  print (word "Test links 2nd created: " count links with [link-interaction-type = "distance-2-test"])
  print (word "Total links created: " count links)

  ; Now export the adjacency matrix
  let num-turtles count turtles
  let adjacency_matrix n-values num-turtles [n-values num-turtles [0]]
  let turtle-list sort turtles

  ; Create the adjacency matrix with different weights for 1st and 2nd neighbors
  ask links [
    let source end1
    let target end2
    let source-index position source turtle-list
    let target-index position target turtle-list

    ; Assign weight based on link label
    let matrix-weight ifelse-value (label = "1st") [1] [0.5]

    ; Update matrix in both directions (undirected graph)
    set adjacency_matrix replace-item source-index adjacency_matrix
      (replace-item target-index (item source-index adjacency_matrix) matrix-weight)
    set adjacency_matrix replace-item target-index adjacency_matrix
      (replace-item source-index (item target-index adjacency_matrix) matrix-weight)
  ]

  ; Export the matrix to file
  file-open "adjacency_matrix.txt"
  file-print "# Adjacency matrix with 1 for first neighbors, 0.5 for second neighbors, 0 for no connection"
  file-print (word "# Matrix size: " num-turtles " x " num-turtles)
  file-print (word "# Total links: " count links)
  file-print (word "# First neighbor links: " count links with [label = "1st"])
  file-print (word "# Second neighbor links: " count links with [label = "2nd"])

  foreach adjacency_matrix [
    row -> file-print (word (sentence row " "))
  ]
  file-close

  ; Also create a sparse matrix format which is more manageable
  file-open "adjacency_matrix_sparse.csv"
  file-print "source,target,weight,label"

  let i 0
  foreach turtle-list [ source ->
    let j 0
    foreach turtle-list [ target ->
      let current-weight item j (item i adjacency_matrix)
      if current-weight > 0 [
        let label-text ifelse-value (current-weight = 1) ["first"] ["second"]
        file-print (word [who] of source "," [who] of target "," current-weight "," label-text)
      ]
      set j j + 1
    ]
    set i i + 1
  ]
  file-close

  print "Network creation and adjacency matrix export complete!"
end

to nodeData
  file-open "nodes.csv"
  let sorted-turtles sort-on [who] turtles
  foreach sorted-turtles [ x ->
    ask x [                                                                 ;; Determine the turtle's species type
    let spType ifelse-value (breed = species0) ["ilex"]
               (ifelse-value (breed = species1) ["Toona"]
               (ifelse-value (breed = species2) ["Cana"]
               (ifelse-value (breed = species3) ["La"]
               (ifelse-value (breed = species4) ["Pet"]
               (ifelse-value (breed = species5) ["An"]
               (ifelse-value (breed = species6) ["Ar"]
               (ifelse-value (breed = species7) ["Gu"]
               (ifelse-value (breed = species8) ["Gr"]
               (ifelse-value (breed = species9) ["Ki"]
               )))))))))
    file-print (word who "," xcor "," ycor "," spType)       ]              ;; Print the turtle's data to the CSV file
  ]
  file-close
end

to linkData
  file-open "links.csv"                                                     ;; Collect all links into a list, then sort by the who number of end1 and then end2
  let all-links [self] of links
  let sorted-links sort all-links
  foreach sorted-links [ x ->                                               ;; Ask each link in the sorted list to print its ends' who numbers
    ask x [
      file-print (word  end1 ","  end2)
    ]
  ]
  file-close
end

; Procedure to create weighted network with first and second neighbors
to create-weighted-network
  ; Clear any existing links before creating new ones
  ask links [ die ]

  ; Define lists for species breeds and their corresponding link colors
  let tree-list (list species1 species2 species3 species4 species5 species6 species7 species8 species9)
  let colors-list (list 53 55 57 63 67 43 75 77 74)
  let tree-colors (map list tree-list colors-list)

  ; Interaction types to consider for weighting
  let selected-type interaction-type ; This would be a global variable or interface control

  ; Loop through each tree species
  foreach tree-colors [ pair ->
    let sp first pair
    let colour last pair

    ; For each ilex plant
    ask species0 [
      let ilex-plant self

      ; Process first neighbors
      ; Find the closest tree of this species
      let min-dist min [distance ilex-plant] of sp
      let closest-tree sp with [distance ilex-plant <= (min-dist)]

      ; Only create links if within threshold distance
      ask closest-tree [
        let this-tree self  ; Store the tree agent for reference
        if min-dist < nearest-neighbor-threshold and draw-w-network? [
          ; Create first-neighbor link
          create-link-with ilex-plant [
            set color colour
            set link-interaction-type (word selected-type "-1") ; Add "-1" to indicate first neighbor
            set label "1st"

             ifelse selected-type = "no-interaction" [
              set weight 0
              set shape "default"
            ][
            ; Calculate weight based on interaction type (for first neighbors)
            ifelse selected-type = "distance" [
              set weight 1
              set shape "default"
            ][
              ifelse selected-type = "shade" [
                set weight (- [size] of this-tree / 12) ; Use this-tree instead of self
                set shape "default"
              ][
                ifelse selected-type = "soil" [
                  let soil-mult 0

                  if [breed] of this-tree = species1 [ set soil-mult [soil-multiplier-Toona] of this-tree ]
                  if [breed] of this-tree = species2 [ set soil-mult [soil-multiplier-Cañafístola] of this-tree ]
                  if [breed] of this-tree = species3 [ set soil-mult [soil-multiplier-Lapacho] of this-tree ]
                  if [breed] of this-tree = species4 [ set soil-mult [soil-multiplier-Petiribí] of this-tree ]
                  if [breed] of this-tree = species5 [ set soil-mult [soil-multiplier-Anchico] of this-tree ]
                  if [breed] of this-tree = species6 [ set soil-mult [soil-multiplier-Araucaria] of this-tree ]
                  if [breed] of this-tree = species7 [ set soil-mult [soil-multiplier-Guatambú] of this-tree ]
                  if [breed] of this-tree = species8 [ set soil-mult [soil-multiplier-Grevillea] of this-tree ]
                  if [breed] of this-tree = species9 [ set soil-mult [soil-multiplier-Kiri] of this-tree ]

                  set weight soil-mult / 0.5
                  set shape "default"
                ][
                  ; Combined effect
                  let dist1-weight 1.0
                  let shade-effect (- [size] of this-tree / 12)

                  let soil-mult 0
                  if [breed] of this-tree = species1 [ set soil-mult [soil-multiplier-Toona] of this-tree ]
                  if [breed] of this-tree = species2 [ set soil-mult [soil-multiplier-Cañafístola] of this-tree ]
                  if [breed] of this-tree = species3 [ set soil-mult [soil-multiplier-Lapacho] of this-tree ]
                  if [breed] of this-tree = species4 [ set soil-mult [soil-multiplier-Petiribí] of this-tree ]
                  if [breed] of this-tree = species5 [ set soil-mult [soil-multiplier-Anchico] of this-tree ]
                  if [breed] of this-tree = species6 [ set soil-mult [soil-multiplier-Araucaria] of this-tree ]
                  if [breed] of this-tree = species7 [ set soil-mult [soil-multiplier-Guatambú] of this-tree ]
                  if [breed] of this-tree = species8 [ set soil-mult [soil-multiplier-Grevillea] of this-tree ]
                  if [breed] of this-tree = species9 [ set soil-mult [soil-multiplier-Kiri] of this-tree ]

                  let soil-effect soil-mult / 0.5

                  set weight dist1-weight + shade-effect + soil-effect

                  ifelse weight >= 0
                    [ set shape "default" ]
                    [ set shape "default" ]
                ]
              ]
            ]
          ]

            ; Set link thickness based on absolute weight
            set thickness abs weight
          ]
        ]
      ]

      ; NOW PROCESS SECOND NEIGHBORS
      ; Find trees within second neighbor threshold but outside first neighbor threshold
      let second-neighbors sp with [
        distance ilex-plant > nearest-neighbor-threshold and
        distance ilex-plant < second-neighbor-threshold and
        not link-neighbor? ilex-plant
       ]

      ; For each second neighbor, create a link
      ask second-neighbors [
        let this-tree self  ; Store the tree agent for reference
        if draw-w-network? [
          ; Create second-neighbor link
          create-link-with ilex-plant [
            set color colour - 10 ; Lighter shade of the species color for second neighbors
            set link-interaction-type (word selected-type "-2") ; Add "-2" to indicate second neighbor
            set label "2nd"

            let dist [distance ilex-plant] of this-tree

            ; Calculate weight based on interaction type (for second neighbors)

             ifelse selected-type = "no-interaction" [
              set weight 0
              set shape "default"
            ][

            ifelse selected-type = "distance" [
              set weight 0.5
              set shape "default"
            ][
              ifelse selected-type = "shade" [
                set weight (- [size] of this-tree / 24)  ; Reduced shade effect for second neighbors
                set shape "default"
              ][
                ifelse selected-type = "soil" [
                  let soil-mult 0

                  if [breed] of this-tree = species1 [ set soil-mult [soil-multiplier-Toona] of this-tree ]
                  if [breed] of this-tree = species2 [ set soil-mult [soil-multiplier-Cañafístola] of this-tree ]
                  if [breed] of this-tree = species3 [ set soil-mult [soil-multiplier-Lapacho] of this-tree ]
                  if [breed] of this-tree = species4 [ set soil-mult [soil-multiplier-Petiribí] of this-tree ]
                  if [breed] of this-tree = species5 [ set soil-mult [soil-multiplier-Anchico] of this-tree ]
                  if [breed] of this-tree = species6 [ set soil-mult [soil-multiplier-Araucaria] of this-tree ]
                  if [breed] of this-tree = species7 [ set soil-mult [soil-multiplier-Guatambú] of this-tree ]
                  if [breed] of this-tree = species8 [ set soil-mult [soil-multiplier-Grevillea] of this-tree ]
                  if [breed] of this-tree = species9 [ set soil-mult [soil-multiplier-Kiri] of this-tree ]

                  set weight (soil-mult / 0.5) * 0.5  ; Reduced effect (50%) for second neighbors
                  set shape "default"
                ][
                  ; Combined effect for second neighbors
                  let dist2-weight 0.5
                  let shade-effect (- [size] of this-tree / 24) ; Reduced shade effect

                  let soil-mult 0
                  if [breed] of this-tree = species1 [ set soil-mult [soil-multiplier-Toona] of this-tree ]
                  if [breed] of this-tree = species2 [ set soil-mult [soil-multiplier-Cañafístola] of this-tree ]
                  if [breed] of this-tree = species3 [ set soil-mult [soil-multiplier-Lapacho] of this-tree ]
                  if [breed] of this-tree = species4 [ set soil-mult [soil-multiplier-Petiribí] of this-tree ]
                  if [breed] of this-tree = species5 [ set soil-mult [soil-multiplier-Anchico] of this-tree ]
                  if [breed] of this-tree = species6 [ set soil-mult [soil-multiplier-Araucaria] of this-tree ]
                  if [breed] of this-tree = species7 [ set soil-mult [soil-multiplier-Guatambú] of this-tree ]
                  if [breed] of this-tree = species8 [ set soil-mult [soil-multiplier-Grevillea] of this-tree ]
                  if [breed] of this-tree = species9 [ set soil-mult [soil-multiplier-Kiri] of this-tree ]

                  let soil-effect (soil-mult / 0.5) * 0.5  ; Reduced soil effect (50%) for second neighbors

                  set weight dist2-weight + shade-effect + soil-effect

                  ifelse weight >= 0
                    [ set shape "default" ]
                    [ set shape "default" ]
                ]
              ]
            ]
          ]

            ; Set link thickness based on absolute weight
            set thickness abs weight
          ]
        ]
      ]
    ]
  ]

  ; Report network creation results
  print (word "Created weighted network with interaction type: " interaction-type)
  print (word "Total links created: " count links)
  print (word "First-neighbor links: " count links with [label = "1st"])
  print (word "Second-neighbor links: " count links with [label = "2nd"])
  print (word "Distance-1 links: " count links with [link-interaction-type = "distance-1"])
  print (word "Distance-2 links: " count links with [link-interaction-type = "distance-2"])
  print (word "Shade-1 links: " count links with [link-interaction-type = "shade-1"])
  print (word "Shade-2 links: " count links with [link-interaction-type = "shade-2"])
  print (word "Soil-1 links: " count links with [link-interaction-type = "soil-1"])
  print (word "Soil-2 links: " count links with [link-interaction-type = "soil-2"])
  print (word "Combined-1 links: " count links with [link-interaction-type = "combined-1"])
  print (word "Combined-2 links: " count links with [link-interaction-type = "combined-2"])

  ; Check a specific ilex plant
  ask one-of species0 [
    print (word "Examining Ilex " who)
    print (word "  First neighbors: " count link-neighbors with [
      not member? self species0 and
      [link-interaction-type] of link-with myself = (word selected-type "-1")
    ])
    print (word "  Second neighbors: " count link-neighbors with [
      not member? self species0 and
      [link-interaction-type] of link-with myself = (word selected-type "-2")
    ])
  ]

  ; Print final counts
  print "======== FINAL LINK COUNTS ========"
  print (word "Total links: " count links)
  print (word "Links with label '1st': " count links with [label = "1st"])
  print (word "Links with label '2nd': " count links with [label = "2nd"])

  ; Check for any unexpected interaction types
  let all-types remove-duplicates [link-interaction-type] of links
  print (word "All interaction types present: " all-types)
end

; Create a multi-interaction network with all interaction types at once
; Extended to handle both first and second neighbors
; In your links-own declaration

; Then in create-multi-interaction-network
to create-multi-interaction-network
  ; Clear any existing links before creating new ones
  ask links [ die ]

  ; Define interaction types to calculate
  let interaction-type-list ["distance" "shade" "soil"]

  ; Define lists for species breeds and their corresponding link colors
  let tree-list (list species1 species2 species3 species4 species5 species6 species7 species8 species9)
  let colors-list (list 53 55 57 63 67 43 75 77 74)
  let tree-colors (map list tree-list colors-list)

  ; Loop through each tree species
  foreach tree-colors [ pair ->
    let sp first pair
    let colour last pair

    ; For each ilex plant
    ask species0 [
      let ilex-plant self

      ; Process first neighbors
      let first-neighbors sp with [distance ilex-plant <= nearest-neighbor-threshold]
      ask first-neighbors [
        let tree-agent self

        ; Calculate distance weight
        let dist1-weight 1.0

        ; Calculate shade weight
        let shade-weight (- [size] of tree-agent / 12)

        ; Calculate soil effect
        let soil-mult 0
        if [breed] of tree-agent = species1 [ set soil-mult [soil-multiplier-Toona] of tree-agent ]
        if [breed] of tree-agent = species2 [ set soil-mult [soil-multiplier-Cañafístola] of tree-agent ]
        if [breed] of tree-agent = species3 [ set soil-mult [soil-multiplier-Lapacho] of tree-agent ]
        if [breed] of tree-agent = species4 [ set soil-mult [soil-multiplier-Petiribí] of tree-agent ]
        if [breed] of tree-agent = species5 [ set soil-mult [soil-multiplier-Anchico] of tree-agent ]
        if [breed] of tree-agent = species6 [ set soil-mult [soil-multiplier-Araucaria] of tree-agent ]
        if [breed] of tree-agent = species7 [ set soil-mult [soil-multiplier-Guatambú] of tree-agent ]
        if [breed] of tree-agent = species8 [ set soil-mult [soil-multiplier-Grevillea] of tree-agent ]
        if [breed] of tree-agent = species9 [ set soil-mult [soil-multiplier-Kiri] of tree-agent ]

        let soil-weight soil-mult / 0.5

        ; Calculate combined weight - now sum of all three interaction types
        let combined-weight dist1-weight + shade-weight + soil-weight

        ; Create a single link with all interaction types
        create-link-with ilex-plant [
          ; Store the interaction type based on the global variable
          ; but we're calculating all types regardless
          set link-interaction-type (word "combined" "-1")
          set label "1st"
          set neighbor-order 1

          ; Store all individual weights
          set weight-distance dist1-weight
          set weight-shade shade-weight
          set weight-soil soil-weight
          set weight-combined combined-weight

          ; Set the primary weight to be the combined weight
          set weight combined-weight

          ; Set color based on combined weight
          ifelse weight >= 0
            [ set color violet ]
            [ set color orange ]

          ; Set thickness based on absolute weight
          set thickness 0.1 + abs weight
        ]
      ]

      ; Process second neighbors
      let second-neighbors sp with [
        distance ilex-plant > nearest-neighbor-threshold and
        distance ilex-plant < second-neighbor-threshold and
        not link-neighbor? ilex-plant
      ]

      ask second-neighbors [
        let tree-agent self

        ; Calculate distance weight
        let dist2-weight 0.5

        ; Calculate shade weight
        let shade-weight (- [size] of tree-agent / 24)

        ; Calculate soil effect
        let soil-mult 0
        if [breed] of tree-agent = species1 [ set soil-mult [soil-multiplier-Toona] of tree-agent ]
        if [breed] of tree-agent = species2 [ set soil-mult [soil-multiplier-Cañafístola] of tree-agent ]
        if [breed] of tree-agent = species3 [ set soil-mult [soil-multiplier-Lapacho] of tree-agent ]
        if [breed] of tree-agent = species4 [ set soil-mult [soil-multiplier-Petiribí] of tree-agent ]
        if [breed] of tree-agent = species5 [ set soil-mult [soil-multiplier-Anchico] of tree-agent ]
        if [breed] of tree-agent = species6 [ set soil-mult [soil-multiplier-Araucaria] of tree-agent ]
        if [breed] of tree-agent = species7 [ set soil-mult [soil-multiplier-Guatambú] of tree-agent ]
        if [breed] of tree-agent = species8 [ set soil-mult [soil-multiplier-Grevillea] of tree-agent ]
        if [breed] of tree-agent = species9 [ set soil-mult [soil-multiplier-Kiri] of tree-agent ]

        let soil-weight (soil-mult / 0.5) * 0.5

        ; Calculate combined weight - now sum of all three interaction types
        let combined-weight dist2-weight + shade-weight + soil-weight

        ; Create a single link with all interaction types
        create-link-with ilex-plant [
          ; Store the interaction type based on the global variable
          ; but we're calculating all types regardless
          set link-interaction-type (word "combined" "-2")
          set label "2nd"
          set neighbor-order 2

          ; Store all individual weights
          set weight-distance dist2-weight
          set weight-shade shade-weight
          set weight-soil soil-weight
          set weight-combined combined-weight

          ; Set the primary weight to be the combined weight
          set weight combined-weight

          ; Set color based on combined weight
          ifelse weight >= 0
            [ set color violet - 10 ]
            [ set color orange - 10 ]

          ; Set thickness based on absolute weight
          set thickness 0.1 + abs weight
        ]
      ]
    ]
  ]

  ; Report network creation results
  print "Created multi-interaction network with all interaction types stored in links"
  print (word "Total links created: " count links)
  print (word "First-neighbor links: " count links with [neighbor-order = 1])
  print (word "Second-neighbor links: " count links with [neighbor-order = 2])

  ; Report counts for all weights
  print "Weight summary:"
  print (word "  Distance-1 weight links: " count links with [neighbor-order = 1 and weight-distance > 0])
  print (word "  Distance-2 weight links: " count links with [neighbor-order = 2 and weight-distance > 0])
  print (word "  Shade-1 weight links: " count links with [neighbor-order = 1 and weight-shade != 0])
  print (word "  Shade-2 weight links: " count links with [neighbor-order = 2 and weight-shade != 0])
  print (word "  Soil-1 weight links: " count links with [neighbor-order = 1 and weight-soil > 0])
  print (word "  Soil-2 weight links: " count links with [neighbor-order = 2 and weight-soil > 0])
  print (word "  Combined-1 weight links: " count links with [neighbor-order = 1 and weight-combined != 0])
  print (word "  Combined-2 weight links: " count links with [neighbor-order = 2 and weight-combined != 0])

  ; Check a specific ilex plant
  ask one-of species0 [
    print (word "Examining Ilex " who)
    let n1 count link-neighbors with [not member? self species0 and [neighbor-order] of link-with myself = 1]
    let n2 count link-neighbors with [not member? self species0 and [neighbor-order] of link-with myself = 2]
    print (word "  First neighbors: " n1)
    print (word "  Second neighbors: " n2)
  ]
end

; New procedure to export weighted adjacency matrix

to export-weighted-matrix-with-time

  let num-turtles count turtles
  let weighted-matrix n-values num-turtles [n-values num-turtles [0]]
  let turtle-list sort turtles

  ; Fill the matrix with link weights
  foreach turtle-list [ source ->
    let source-index position source turtle-list
    ask source [
      ask my-links [
        let target ifelse-value (end1 = source) [end2] [end1]
        let target-index position target turtle-list
        set weighted-matrix replace-item source-index weighted-matrix (replace-item target-index (item source-index weighted-matrix) weight)
        set weighted-matrix replace-item target-index weighted-matrix (replace-item source-index (item target-index weighted-matrix) weight)

      ]
    ]
  ]
  ; Export to file
  let filename (word "weighted_matrix_" interaction-type "_tick_" ticks ".csv")
  file-open filename
  file-print "source,target,weight,type,link-interaction-type"
  ; Write matrix in edge list format (more useful for network analysis)
  let i 0
  foreach turtle-list [ source ->
    let j 0
    foreach turtle-list [ target ->
      let w item j item i weighted-matrix
      if w != 0 [
        let source-id [who] of source
        let target-id [who] of target
        let source-type [breed] of source
        let target-type [breed] of target

        ; Find the actual link to get interaction type
        let int-type "unknown"
        ask source [
          ask my-links with [
            (end1 = source and end2 = target) or
            (end1 = target and end2 = source)
          ] [
            set int-type link-interaction-type
          ]
        ]

        file-print (word source-id "," target-id "," w "," source-type "-" target-type "," int-type)
      ]
      set j j + 1
    ]
    set i i + 1
  ]
  file-close
  ; Print debugging information
    print (word "Matrix exported to " filename)
    print (word "Total links in network: " count links)
    print (word "First-neighbor links: " count links with [label = "1st"])
    print (word "Second-neighbor links: " count links with [label = "2nd"])
    print (word "Links written to file: " count links)
    print "File format: source,target,weight,type,link-interaction-type"
end


to export-weighted-matrix-with-coordinates
  let num-turtles count turtles
  let weighted-matrix n-values num-turtles [n-values num-turtles [0]]
  let turtle-list sort turtles

  ; Fill the matrix with link weights
  foreach turtle-list [ source ->
    let source-index position source turtle-list
    ask source [
      ask my-links [
        let target ifelse-value (end1 = source) [end2] [end1]
        let target-index position target turtle-list
        set weighted-matrix replace-item source-index weighted-matrix (replace-item target-index (item source-index weighted-matrix) weight)
        set weighted-matrix replace-item target-index weighted-matrix (replace-item source-index (item target-index weighted-matrix) weight)
      ]
    ]
  ]

  ; Export edge list with coordinates to file
  let filename (word "weighted_matrix_with_coords_" interaction-type "_tick_" ticks ".csv")
  file-open filename

  ; Modified header to include coordinates
  file-print "source,target,weight,type,link-interaction-type,source_x,source_y,target_x,target_y"

  ; Write matrix in edge list format with coordinates
  let i 0
  foreach turtle-list [ source ->
    let j 0
    foreach turtle-list [ target ->
      let w item j item i weighted-matrix
      if w != 0 [
        let source-id [who] of source
        let target-id [who] of target
        let source-type [breed] of source
        let target-type [breed] of target

        ; Get coordinates for source and target
        let source-x [xcor] of source
        let source-y [ycor] of source
        let target-x [xcor] of target
        let target-y [ycor] of target

        ; Find the actual link to get interaction type
        let int-type "unknown"
        ask source [
          ask my-links with [
            (end1 = source and end2 = target) or
            (end1 = target and end2 = source)
          ] [
            set int-type link-interaction-type
          ]
        ]

        ; Write line with coordinates
        file-print (word source-id "," target-id "," w "," source-type "-" target-type "," int-type ","
                   source-x "," source-y "," target-x "," target-y)
      ]
      set j j + 1
    ]
    set i i + 1
  ]
  file-close

  ; Print debugging information
  print (word "Matrix with coordinates exported to " filename)
  print (word "Total links in network: " count links)
  print (word "First-neighbor links: " count links with [label = "1st"])
  print (word "Second-neighbor links: " count links with [label = "2nd"])
  print (word "Links written to file: " count links)
  print "File format: source,target,weight,type,link-interaction-type,source_x,source_y,target_x,target_y"
end

; Additionally, we can create a procedure to export only node coordinates
to export-node-coordinates
  let filename (word "node_coordinates_tick_" ticks ".csv")
  file-open filename

  ; Header for node coordinates file
  file-print "node_id,breed,xcor,ycor"

  ; Write coordinates for all turtles
  ask turtles [
    file-print (word who "," breed "," xcor "," ycor)
  ]
  file-close
  print (word "Node coordinates exported to " filename)
end

to set-soil-factor
  ask patches      [
      ifelse  soil = soil1 [ set soil-factor  1.12   ]
      [ifelse soil = soil2 [ set soil-factor 1.0 ]
      [ifelse soil = soil3 [ set soil-factor 0.95 ]
      [ifelse soil = soil4 [ set soil-factor 0.85 ]
                           [ set soil-factor 0.80 ]
          ]
        ]
      ]
  ]
end

to energy-account
  set N  count patches                                   ;; the number of patches will be used to obtain averages
  if start? [
        ask patches  [ set soil-energy soil  ]           ;; It is a duplicate that facilitates operations: growth, crop, trimming, fertilization which are operationalized for each soil type
        set start? false                                 ;; scaling soil type to growth energy; more fertility more energy given to plants in energy-trees
  ]
  ask turtles
      [ set et 2.5 * soil-factor
  ]
    foreach (range 10) [ i ->
    let species-name (word "species" i)
    let energy-var (word "energy-" (item i ["ilex" "Toona" "Cañafístola" "Lapacho" "Petiribí" "Anchico" "Araucaria" "Guatambú" "Grevillea" "Kiri"]))
    ask (turtle-set runresult species-name) [
      run (word "set " energy-var " 1 * et")             ;; each species will obtain a species-specific amount of energy; here the scaling is 1
    ]
  ]
end

to grow
  ask species0 [ recalibrate-ilex-growth  growth-rate-ilex]
  ask species1 [ grow-at-rate growth-rate-toona ]
  ask species2 [ grow-at-rate growth-rate-cana ]
  ask species3 [ grow-at-rate growth-rate-la ]
  ask species4 [ grow-at-rate growth-rate-pet ]
  ask species5 [ grow-at-rate growth-rate-an ]
  ask species6 [ grow-at-rate growth-rate-ar ]
  ask species7 [ grow-at-rate growth-rate-gu ]
  ask species8 [ grow-at-rate growth-rate-gr ]
  ask species9 [ grow-at-rate growth-rate-ki ]
  ifelse ticks <= 156
  [ set growth-energy-uptake (et * Ni + et * Nt) / 3 ]
  [ set growth-energy-uptake (et * Ni + et * Nt) / 2 ]

  ask patches [set soil-energy   soil-energy - growth-energy-uptake]

  print "Sizes of three species0 turtles Growing :"
  ask up-to-n-of 3 species0 [
    print (word "Turtle " who ": size = " size)
  ]
   print "Sizes of three species1 turtles Growing:"
  ask up-to-n-of 3 species1 [
    print (word "Turtle " who ": size = " size)
  ]
end

to recalibrate-ilex-growth [rate]
  let combined-soil-factor soil-factor * [local-soil-factor] of patch-here
  set size size * (((1 + rate) ^ (1 / 2)) * combined-soil-factor)

end

to grow-at-rate [rate]
  set size size * (((1 + rate ) ^ (1 / 2) ) * soil-factor)

end

to-report system-growth-energy-uptake
report growth-energy-uptake
end

to compete-shade
  ask species0 [                                                               ;; Create an agentset of all other species
    let tree-agentset (turtle-set tree-set)                                    ;; Find neighbors within a radius of 7.5, excluding self
    let nearby-neighbors tree-agentset in-radius 7.5                           ;; Find up to 4 closest neighbors from those within radius 7.5
    let closest-neighbors ifelse-value (count nearby-neighbors >= 4)
      [ min-n-of 4 nearby-neighbors [distance myself] ]
      [ nearby-neighbors ]                                                     ;; If fewer than 4 neighbors within radius 7.5, use all of them
    if any? closest-neighbors [                                                ;; Only proceed if there are any close neighbors
    let avg-size mean [size] of closest-neighbors                              ;; Calculate the average size of these closest neighbors
    let shade-factor max (list (1 - (avg-size / 30) ^ 2)  0.7)                 ;; Ensure shade doesn't reduce growth by more than 70%
    ifelse avg-size > tree-thin-size [set size size * shade-factor             ;; Reduce size if average size is greater than 9, same size that triggers thinning
      ]
      [
        if size < 9 [ stop                                                     ;; normal increase in size if less than 9
        ]
      ]
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to harvest-ilex
  print "Harvest-ilex called"
  print "Sizes of three species0 turtles before harvest:"
  ask up-to-n-of 3 species0 [
    print (word "Turtle " who ": size = " size)
  ]

  let filename (word "harvest_per_plant.csv")
  file-open filename
  file-print "tick,who,harvested,total_neighbors,species1_neighbors,species2_neighbors,species3_neighbors,species4_neighbors,species5_neighbors,species6_neighbors,species7_neighbors,species8_neighbors,species9_neighbors"

  let individual-harvest 0
  ask species0 [
    if size >= harvest-size [
      let local-harvest-rate harvest-rate
      if size >= 12 [
        set local-harvest-rate harvest-rate * 1.5
      ]

      set individual-harvest size * harvest-rate
      set harvest-amount lput individual-harvest harvest-amount
      set size size * (1 - local-harvest-rate)
      set energy-ilex (energy-ilex - 1.25 * harvest-rate * et)
      set total-harvest (sum harvest-amount)
      set soil-multiplier-mate ((sum harvest-amount * 0.75) * convert-dry * convert-SOM)

      ;; Count neighbors by species type
      let total-neighbors count link-neighbors
      let species1-neighbors count (link-neighbors with [breed = species1])
      let species2-neighbors count (link-neighbors with [breed = species2])
      let species3-neighbors count (link-neighbors with [breed = species3])
      let species4-neighbors count (link-neighbors with [breed = species4])
      let species5-neighbors count (link-neighbors with [breed = species5])
      let species6-neighbors count (link-neighbors with [breed = species6])
      let species7-neighbors count (link-neighbors with [breed = species7])
      let species8-neighbors count (link-neighbors with [breed = species8])
      let species9-neighbors count (link-neighbors with [breed = species9])

      ;; Export each turtle's record to CSV with neighbor breakdown
      file-print (word ticks "," who "," individual-harvest ","
                      total-neighbors "," species1-neighbors "," species2-neighbors ","
                      species3-neighbors "," species4-neighbors "," species5-neighbors ","
                      species6-neighbors "," species7-neighbors "," species8-neighbors ","
                      species9-neighbors)
    ]
  ]
  file-close
  ;; Create analysis summary
  create-harvest-by-species-analysis

  print (word "tick " ticks " total harvest: " sum harvest-amount)
  print "Sizes of three species0 turtles after harvest:"
  ask up-to-n-of 3 species0 [
    print (word "Turtle " who ": size = " size)
  ]
  print (word "sum harvest-amount : " sum harvest-amount)
  print (word "soil-multiplier-mate-Increment: " soil-multiplier-mate)
  update-soil-multipliers-mate soil-multiplier-mate
  file-close
end

to create-harvest-by-species-analysis
  let analysis-filename (word "harvest_analysis_by_species_" ticks ".csv")
  file-open analysis-filename
  file-print "neighbor_species,total_harvest,avg_harvest_per_plant,num_plants,avg_neighbors_per_plant"

  ;; Analyze harvest for plants with each species neighbor type
  foreach (range 1 10) [ i ->
    let species-breed runresult (word "species" i)
    let ilex-with-this-neighbor species0 with [any? link-neighbors with [breed = species-breed]]

    if count ilex-with-this-neighbor > 0 [
      ;; Only include plants that were actually harvested in this tick (size >= harvest-size)
      let harvested-ilex-with-this-neighbor ilex-with-this-neighbor with [size >= harvest-size]

      if count harvested-ilex-with-this-neighbor > 0 [
        ;; Calculate harvest for each plant in this group (same formula as in harvest-ilex)
        let total-harvest-this-species 0
        let harvest-count 0

        ask harvested-ilex-with-this-neighbor [
          let local-harvest-rate harvest-rate
          if size >= 12 [
            set local-harvest-rate harvest-rate * 1.5
          ]
          let this-plant-harvest size * harvest-rate
          set total-harvest-this-species total-harvest-this-species + this-plant-harvest
          set harvest-count harvest-count + 1
        ]

        ;; Calculate statistics for this group
        let avg-harvest-this-species total-harvest-this-species / harvest-count
        let num-plants-this-species count harvested-ilex-with-this-neighbor

        ;; Calculate average neighbors of this species type
        let total-neighbors-count 0
        ask harvested-ilex-with-this-neighbor [
          set total-neighbors-count total-neighbors-count + count (link-neighbors with [breed = species-breed])
        ]
        let avg-neighbors-this-species total-neighbors-count / num-plants-this-species

        file-print (word "species" i "," total-harvest-this-species ","
                        avg-harvest-this-species "," num-plants-this-species "," avg-neighbors-this-species)
      ]
    ]
  ]

  ;; Also analyze ilex with no tree neighbors
  let ilex-no-neighbors species0 with [count link-neighbors = 0]
  let harvested-ilex-no-neighbors ilex-no-neighbors with [size >= harvest-size]

  if count harvested-ilex-no-neighbors > 0 [
    ;; Calculate harvest for no-neighbor plants
    let total-harvest-no-neighbors 0
    let harvest-count-no-neighbors 0

    ask harvested-ilex-no-neighbors [
      let local-harvest-rate harvest-rate
      if size >= 12 [
        set local-harvest-rate harvest-rate * 1.5
      ]
      let this-plant-harvest size * harvest-rate
      set total-harvest-no-neighbors total-harvest-no-neighbors + this-plant-harvest
      set harvest-count-no-neighbors harvest-count-no-neighbors + 1
    ]

    let avg-harvest-no-neighbors total-harvest-no-neighbors / harvest-count-no-neighbors
    let num-plants-no-neighbors count harvested-ilex-no-neighbors

    file-print (word "no_tree_neighbors," total-harvest-no-neighbors ","
                    avg-harvest-no-neighbors "," num-plants-no-neighbors ",0")
  ]

  file-close
end

to-report total-harvest-mate
  report  [round total-harvest] of species0
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to harvest-ilex-nearest-neighbors
  print "Harvest-ilex-nearest-neighbors called"

  let filename (word "harvest_per_plant_nearest_neighbors.csv")
  file-open filename
  file-print "tick,who,harvested,total_nearest_neighbors,species1_nearest,species2_nearest,species3_nearest,species4_nearest,species5_nearest,species6_nearest,species7_nearest,species8_nearest,species9_nearest"

  let individual-harvest 0
  ask species0 [
    if size >= harvest-size [
      let local-harvest-rate harvest-rate
      if size >= 12 [
        set local-harvest-rate harvest-rate * 1.5
      ]

      set individual-harvest size * harvest-rate

      ;; Count ONLY nearest neighbors (using same logic as create-network)
      let tree-list (list species1 species2 species3 species4 species5 species6 species7 species8 species9)

      ;; Initialize nearest neighbor counts
      let species1-nearest 0
      let species2-nearest 0
      let species3-nearest 0
      let species4-nearest 0
      let species5-nearest 0
      let species6-nearest 0
      let species7-nearest 0
      let species8-nearest 0
      let species9-nearest 0
      let total-nearest-neighbors 0

      ;; For each species, find the nearest neighbors within threshold
      let ilex-plant self

      foreach (range 0 9) [ i ->
        let sp item i tree-list
        if count sp > 0 [
          ;; Find minimum distance to any turtle of this species
          let min-dist min [distance ilex-plant] of sp
          ;; Find all trees of this species at minimum distance
          let closest-trees sp with [distance ilex-plant = min-dist]
          ;; Only count if within nearest neighbor threshold (7.1)
          if min-dist < 7.1 [
            let nearest-count count closest-trees
            ;; Assign to appropriate species counter
            if i = 0 [ set species1-nearest nearest-count ]
            if i = 1 [ set species2-nearest nearest-count ]
            if i = 2 [ set species3-nearest nearest-count ]
            if i = 3 [ set species4-nearest nearest-count ]
            if i = 4 [ set species5-nearest nearest-count ]
            if i = 5 [ set species6-nearest nearest-count ]
            if i = 6 [ set species7-nearest nearest-count ]
            if i = 7 [ set species8-nearest nearest-count ]
            if i = 8 [ set species9-nearest nearest-count ]
            set total-nearest-neighbors total-nearest-neighbors + nearest-count
          ]
        ]
      ]

      ;; Export each turtle's record to CSV with nearest neighbor breakdown
      file-print (word ticks "," who "," individual-harvest ","
                      total-nearest-neighbors "," species1-nearest "," species2-nearest ","
                      species3-nearest "," species4-nearest "," species5-nearest ","
                      species6-nearest "," species7-nearest "," species8-nearest ","
                      species9-nearest)
    ]
  ]

  file-close

  ;; Create nearest neighbors analysis summary
  create-harvest-by-nearest-neighbors-analysis

  print "Nearest neighbors harvest analysis completed"
end

;; Analysis procedure for nearest neighbors only
to create-harvest-by-nearest-neighbors-analysis
  let analysis-filename (word "harvest_analysis_nearest_neighbors_" ticks ".csv")
  file-open analysis-filename
  file-print "neighbor_species,total_harvest,avg_harvest_per_plant,num_plants,avg_nearest_neighbors_per_plant"

  ;; Define tree species list
  let tree-list (list species1 species2 species3 species4 species5 species6 species7 species8 species9)

  ;; Analyze harvest for plants with each species as nearest neighbor
  foreach (range 0 9) [ i ->
    let sp item i tree-list
    let species-num i + 1

    ;; Find ilex plants that have this species as nearest neighbor
    let ilex-with-nearest-neighbor species0 with [
      count sp > 0 and min [distance myself] of sp < 7.1
    ]

    if count ilex-with-nearest-neighbor > 0 [
      ;; Only include plants that were actually harvested
      let harvested-ilex-with-nearest ilex-with-nearest-neighbor with [size >= harvest-size]

      if count harvested-ilex-with-nearest > 0 [
        ;; Calculate harvest for each plant in this group
        let total-harvest-this-species 0
        let harvest-count 0
        let total-nearest-count 0

        ask harvested-ilex-with-nearest [
          let local-harvest-rate harvest-rate
          if size >= 12 [
            set local-harvest-rate harvest-rate * 1.5
          ]
          let this-plant-harvest size * harvest-rate
          set total-harvest-this-species total-harvest-this-species + this-plant-harvest
          set harvest-count harvest-count + 1

          ;; Count nearest neighbors of this species for this plant
          let min-dist min [distance myself] of sp
          let nearest-of-this-species count (sp with [distance myself = min-dist and distance myself < 7.1])
          set total-nearest-count total-nearest-count + nearest-of-this-species
        ]

        ;; Calculate statistics for this group
        let avg-harvest-this-species total-harvest-this-species / harvest-count
        let num-plants-this-species count harvested-ilex-with-nearest
        let avg-nearest-this-species total-nearest-count / num-plants-this-species

        file-print (word "species" species-num "," total-harvest-this-species ","
                        avg-harvest-this-species "," num-plants-this-species "," avg-nearest-this-species)
      ]
    ]
  ]

  ;; Also analyze ilex with no nearest neighbors (control group)
  let ilex-no-nearest-neighbors species0

  ;; Filter out plants that have ANY species as nearest neighbor
  ask ilex-no-nearest-neighbors [
    let has-nearest-neighbor false
    let ilex-plant self
    foreach tree-list [ sp ->
      if count sp > 0 [
        let min-dist min [distance ilex-plant] of sp
        if min-dist < 7.1 [
          set has-nearest-neighbor true
        ]
      ]
    ]
    if has-nearest-neighbor [
      set ilex-no-nearest-neighbors ilex-no-nearest-neighbors with [self != ilex-plant]
    ]
  ]

  let harvested-ilex-no-nearest ilex-no-nearest-neighbors with [size >= harvest-size]

  if count harvested-ilex-no-nearest > 0 [
    ;; Calculate harvest for control group
    let total-harvest-no-nearest 0
    let harvest-count-no-nearest 0

    ask harvested-ilex-no-nearest [
      let local-harvest-rate harvest-rate
      if size >= 12 [
        set local-harvest-rate harvest-rate * 1.5
      ]
      let this-plant-harvest size * harvest-rate
      set total-harvest-no-nearest total-harvest-no-nearest + this-plant-harvest
      set harvest-count-no-nearest harvest-count-no-nearest + 1
    ]

    let avg-harvest-no-nearest total-harvest-no-nearest / harvest-count-no-nearest
    let num-plants-no-nearest count harvested-ilex-no-nearest

    file-print (word "no_nearest_neighbors," total-harvest-no-nearest ","
                    avg-harvest-no-nearest "," num-plants-no-nearest ",0")
  ]

  file-close
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to trim-trees
  print "Sizes of three species1 turtles before trim:"
  ask up-to-n-of 3 species1 [
    print (word "Turtle " who ": size = " size)
  ]
  let tree-harvest 0
  set species-multipliers table:make                                             ;; Use a table to track multipliers per species
  let trim-factors [0.61  0.75  0.67  0.69  0.76  0.8  0.64  0.74  0.65]         ;; The product of these factors with growth rates equals 1.
  let species-names ["Toona" "Cañafístola" "Lapacho" "Petiribí" "Anchico" "Araucaria" "Guatambú" "Grevillea" "Kiri"]

  foreach (range 1 10) [ i ->
    let breed-name (word "species" (i))
    let species-name item (i - 1) species-names
    let trim-factor item (i - 1) trim-factors
    let multipliers-species-contribution 0

    ask (turtle-set runresult breed-name) [
      if size > tree-trim-size [
        set tree-harvest size * (1 - trim-factor)
        set harvest-trees (tree-harvest)
        set size size * trim-factor
        let current-energy runresult (word "energy-" species-name)
        run (word "set energy-" species-name " " (current-energy - 0.3 * et))

        ; Calculate this tree's contribution
        let tree-soil-contribution harvest-trees * (convert-dry * convert-SOM)

        ; Add to the species total
        set multipliers-species-contribution multipliers-species-contribution + tree-soil-contribution

        ; IMPORTANT NEW CODE: Assign soil multiplier value to this specific tree
        run (word "set soil-multiplier-" species-name " " tree-soil-contribution)
      ]
    ]
    table:put species-multipliers species-name multipliers-species-contribution
  ]
  print (word "Table species-multipliers: " species-multipliers)
  let total-increment-multipliers sum table:values species-multipliers
  print (word "Total-increment-multipliers sum: " total-increment-multipliers)
  update-soil-multipliers-trimm total-increment-multipliers
end


to fertilize
  let fertilizers-solubility  soil-multiplier * buffer-factor
  set  fertilizer-amount  ( reposition / 100 ) * growth-energy-uptake * 0.5        ;; percentage of tree consumption that is externally supplied
  set soil-gain fertilizer-amount * ( 1 + 1 * fertilizers-solubility)            ;; the external imput is leveraged by the multipliers
  ask patches [ set soil-energy  ( soil-energy + soil-gain ) ]                   ;; soil-energy is incrased by the gain from the direct
  print-harvest-fertilizer-stats                                                 ;; energy multipliers contribution, the external imput, and the multipliers on the external imput
end

to print-harvest-fertilizer-stats
  ifelse total-harvest > 0 [
    let ratio ( fertilizer-amount / total-harvest )
    print (word "fertilizer-harvest-ratio: " ratio )
  ]
    [ let ratio 0
    print (word "fertilizer-harvest-ratio: " ratio )
  ]
  print (word "Total harvest: " total-harvest )
  print (word "Growth Energy Uptake: " growth-energy-uptake )
  print (word "soil-multiplier-for-fertilizer-amount: " soil-multiplier )
  print (word "soil-energy: " mean [soil-energy] of patches)
  print (word "Fertilizer amount: " fertilizer-amount )
  print (word "Fertilizer-Harvest Ratio: " fertilizer-harvest-ratio)
end

to perform-thinning [ycor-list]
  ask turtles [
      if size > tree-thin-size and member? ycor ycor-list [
      thin-tree
    ]
  ]
end


to decay-local-soil-factor
  let decay-rate 0.0268
  let time-rebalance ( ticks - last-rebalance ) * 1
  set last-rebalance  ticks
  set previous-soil-energy mean [soil-energy] of patches

  ask patches [
    if local-soil-factor > 1 [
      set local-soil-factor local-soil-factor * exp(- decay-rate * time-rebalance)      ;; Adjust this value as needed
      if local-soil-factor < 1 [set local-soil-factor 1]
    ]
  ]
end

to rebalance-soil
  let decay-rate 0.0268
  let time-rebalance ( ticks - last-rebalance ) * 1
  write (word "time-rebalance:" time-rebalance)

  let current mean [soil-energy] of patches
  ifelse previous-soil-energy > 0 [  set soil-energy-improvement (current / previous-soil-energy) ]
  [   ]
  if minreposition? = True [
  ifelse soil-energy-improvement > 1.44 [                                                    ;; If improvement is greater than 20%
      set reposition max ( list (reposition * 0.6 ) 10 )                                     ;; Reduce by 20% but not below 10%
      print (word "Soil improvement: " precision ((soil-energy-improvement - 1) * 100) 1 "%")
      print (word "Reducing reposition to: " reposition "%")
  ]
     [if soil-energy-improvement < 1 [                                                       ;; If improvement is greater than 25%
      set reposition  min ( list (reposition * 1.20 ) 200  )] ]                              ;;

      print (word "Soil improvement: " precision ((soil-energy-improvement - 1) * 100) 1 "%")
      print (word "Reducing reposition to: " reposition "%")
  ]
  set soil-multiplier soil-multiplier * exp(- decay-rate * time-rebalance)
  set soil-multiplier-mate soil-multiplier-mate * exp(- decay-rate * time-rebalance)
  set soil-multiplier-trees soil-multiplier-trees * exp(- decay-rate * time-rebalance)

  set last-rebalance  ticks
  ask patches [
    if local-soil-factor > 1 [
      set local-soil-factor local-soil-factor * exp(- decay-rate  * time-rebalance)     ;; Adjust this value as needed
      if local-soil-factor < 1 [set local-soil-factor 1]
    ]
  ]
  ask patches [set soil current-soil-energy ]                                           ;; the soil type changes and the colors change to map this continuously
  ask patches
  [ if 8000 <= soil
    [set pcolor    49
     set soil1 soil ]
  if 6000 <= soil and soil <= 8000
    [set pcolor    39
     set soil2 soil ]
  if 4000 <= soil and soil <= 6000
    [set pcolor    29
     set soil3 soil ]
  if 2000 <= soil and soil <= 4000
    [set pcolor    19
     set soil4 soil ]
  if soil <= 2000
   [set pcolor  139
     set soil5 soil ]
  ]
 end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; IMPROVED: Clean logging with separate columns for event types and values

;; Modified header to include separate increment value column
to initialize-soil-monitoring
  set soil-csv-header-written? false
end

;; IMPROVED: Main procedure with clean data format
to log-soil-data [event-type event-details increment-value]
  let filename "comprehensive_soil_data.csv"
  file-open filename

  ;; Write header only once - IMPROVED with separate increment column
  if not soil-csv-header-written? [
    file-print "tick,event_type,event_details,increment_value,soil_multiplier_mate,soil_multiplier_trees,soil_multiplier_increment,total_soil_multiplier,avg_soil_gain,avg_soil_energy,species1_contrib,species2_contrib,species3_contrib,species4_contrib,species5_contrib,species6_contrib,species7_contrib,species8_contrib,species9_contrib,total_species_contrib,num_patches"
    set soil-csv-header-written? true
  ]

  ;; Get current soil status
  let current-avg-soil-gain mean [soil-gain] of patches
  let current-avg-soil-energy mean [soil-energy] of patches
  let current-patch-count count patches

  ;; Get species contributions (same as before)
  let species1-contrib 0  ; Toona
  let species2-contrib 0  ; Cañafístola
  let species3-contrib 0  ; Lapacho
  let species4-contrib 0  ; Petiribí
  let species5-contrib 0  ; Anchico
  let species6-contrib 0  ; Araucaria
  let species7-contrib 0  ; Guatambú
  let species8-contrib 0  ; Grevillea
  let species9-contrib 0  ; Kiri

  ;; Get values from individual species
  if any? species1 [ set species1-contrib mean [soil-multiplier-Toona] of species1 ]
  if any? species2 [ set species2-contrib mean [soil-multiplier-Cañafístola] of species2 ]
  if any? species3 [ set species3-contrib mean [soil-multiplier-Lapacho] of species3 ]
  if any? species4 [ set species4-contrib mean [soil-multiplier-Petiribí] of species4 ]
  if any? species5 [ set species5-contrib mean [soil-multiplier-Anchico] of species5 ]
  if any? species6 [ set species6-contrib mean [soil-multiplier-Araucaria] of species6 ]
  if any? species7 [ set species7-contrib mean [soil-multiplier-Guatambú] of species7 ]
  if any? species8 [ set species8-contrib mean [soil-multiplier-Grevillea] of species8 ]
  if any? species9 [ set species9-contrib mean [soil-multiplier-Kiri] of species9 ]

  ;; Alternative: table approach
  if table:length species-multipliers > 0 [
    if table:has-key? species-multipliers 1 [ set species1-contrib table:get species-multipliers 1 ]
    if table:has-key? species-multipliers 2 [ set species2-contrib table:get species-multipliers 2 ]
    if table:has-key? species-multipliers 3 [ set species3-contrib table:get species-multipliers 3 ]
    if table:has-key? species-multipliers 4 [ set species4-contrib table:get species-multipliers 4 ]
    if table:has-key? species-multipliers 5 [ set species5-contrib table:get species-multipliers 5 ]
    if table:has-key? species-multipliers 6 [ set species6-contrib table:get species-multipliers 6 ]
    if table:has-key? species-multipliers 7 [ set species7-contrib table:get species-multipliers 7 ]
    if table:has-key? species-multipliers 8 [ set species8-contrib table:get species-multipliers 8 ]
    if table:has-key? species-multipliers 9 [ set species9-contrib table:get species-multipliers 9 ]
  ]

  ;; Calculate total species contribution
  let total-species-contrib (species1-contrib + species2-contrib + species3-contrib +
                            species4-contrib + species5-contrib + species6-contrib +
                            species7-contrib + species8-contrib + species9-contrib)

  ;; IMPROVED: Write data row with clean format
  file-print (word ticks ","
                  event-type ","
                  event-details ","
                  increment-value ","
                  soil-multiplier-mate ","
                  soil-multiplier-trees ","
                  soil-multiplier-increment ","
                  soil-multiplier ","
                  current-avg-soil-gain ","
                  current-avg-soil-energy ","
                  species1-contrib ","
                  species2-contrib ","
                  species3-contrib ","
                  species4-contrib ","
                  species5-contrib ","
                  species6-contrib ","
                  species7-contrib ","
                  species8-contrib ","
                  species9-contrib ","
                  total-species-contrib ","
                  current-patch-count)

  file-close
end

;; IMPROVED: Modified update procedures with clean logging
to update-soil-multipliers-trimm [increment]
  let old-soil-multiplier soil-multiplier
  set soil-multiplier-trees soil-multiplier-trees + increment
  set soil-multiplier (soil-multiplier + soil-multiplier-trees)

  ask patches [
    set soil-gain soil-multiplier-trees
    set soil-energy (soil-energy + soil-gain)
  ]

  ;; IMPROVED: Clean logging with separate increment value
  log-soil-data "trimming" "tree_trimming" increment

  ;; Keep original print statements
  print (word "Old multiplier: " old-soil-multiplier)
  print (word "Soil-multiplier-trees Trim-Increment: " increment)
  print (word "New soil-multiplier: " soil-multiplier)
  print (word "Soil gain: " soil-multiplier-trees)
  print (word "Average soil gain: " mean [soil-gain] of patches)
end

;; IMPROVED: Modified mate harvest procedure
to update-soil-multipliers-mate [increment]
  let old-soil-multiplier soil-multiplier
  set soil-multiplier-mate soil-multiplier-mate + increment
  set soil-multiplier (soil-multiplier + soil-multiplier-mate)

  ask patches [
    set soil-gain soil-multiplier-mate
    set soil-energy (soil-energy + soil-gain)
  ]

  ;; IMPROVED: Clean logging with separate increment value
  log-soil-data "mate_harvest" "harvest_event" increment

  ;; Keep original print statements
  print (word "old-soil-multiplier: " old-soil-multiplier)
  print (word "new-soil-multiplier: " soil-multiplier)
end

;; IMPROVED: Modified thinning procedure
to update-soil-multipliers-thinning [increment species-id]
  let old-soil-multiplier soil-multiplier
  set soil-multiplier-increment soil-multiplier-increment + increment
  set soil-multiplier (soil-multiplier + soil-multiplier-increment)

  ;; Update species-specific contribution in table
  if table:has-key? species-multipliers species-id [
    let current-value table:get species-multipliers species-id
    table:put species-multipliers species-id (current-value + increment)
  ]
    table:put species-multipliers species-id increment


  ask patches [
    set soil-gain soil-multiplier-increment
    set soil-energy (soil-energy + soil-gain)
  ]

  ;; IMPROVED: Clean logging with separate increment value
  log-soil-data "thinning" (word "species_" species-id) increment

  print (word "Thinning species " species-id " with increment: " increment)
  print (word "New soil multiplier: " soil-multiplier)
end

;; NEW: Modified thin-tree procedure to include logging
to thin-tree
  let original-size size
  set size 1.5
  set thinned-amount ( original-size - 1.5 )
  set soil-multiplier-increment  thinned-amount * convert-dry * convert-SOM
  set thinned-count thinned-count + 1

  ask patches in-radius 10 [
    set local-soil-factor local-soil-factor + 0.12
  ]

  set soil-multiplier-trees soil-multiplier-trees + soil-multiplier-increment
  set soil-gain soil-multiplier-increment
  set soil-energy ( soil-energy + soil-gain )

  ;; NEW: Log the individual thinning event with clean format
  ;; Determine species ID based on breed
  let species-id 0
  if breed = species1 [ set species-id 1 ]
  if breed = species2 [ set species-id 2 ]
  if breed = species3 [ set species-id 3 ]
  if breed = species4 [ set species-id 4 ]
  if breed = species5 [ set species-id 5 ]
  if breed = species6 [ set species-id 6 ]
  if breed = species7 [ set species-id 7 ]
  if breed = species8 [ set species-id 8 ]
  if breed = species9 [ set species-id 9 ]

  log-soil-data "thinning" (word "individual_tree_species_" species-id) soil-multiplier-increment

  ;; Keep original print statements
  print (word "thinned-count : " thinned-count )
  print (word "soil-multiplier-trees Thin-Increment: " soil-multiplier-increment)
  print (word "soil-multiplier-trees: " soil-multiplier-trees)
  print (word "soil-gain: " soil-gain)
  print (word "soil-energy: " soil-energy)
  print (word "local-soil-factor: " local-soil-factor)
end

;; NEW: Modified thinning procedures to include summary logging
to thinning1
  if thiniter1? [
    let trees-before-thinning thinned-count
    perform-thinning [5 25 45 65 85 105 125 145 165 185 205]
    let trees-thinned (thinned-count - trees-before-thinning)

    ;; Log the thinning event summary
    log-soil-data "thinning_event" "thinning1_complete" trees-thinned

    set countert1 ticks
    set thinned-count 0
    set thiniter1? false
    set thiniter2? true

    print (word "Thinning1 completed at tick " ticks " - " trees-thinned " trees thinned")
  ]
end

to thinning2
  if thiniter2? [
    let trees-before-thinning thinned-count
    perform-thinning [15 35 55 75 95 115 135 155 175 195 215]
    let trees-thinned (thinned-count - trees-before-thinning)

    ;; Log the thinning event summary
    log-soil-data "thinning_event" "thinning2_complete" trees-thinned

    set thinned-count 0
    set thiniter1? true
    set thiniter2? false

    print (word "Thinning2 completed at tick " ticks " - " trees-thinned " trees thinned")
  ]
end

;; IMPROVED: General procedure for any soil event with clean format
to log-general-soil-event [event-name details increment-val]
  log-soil-data event-name details increment-val
end

;; IMPROVED: Enhanced reporting procedures with clean logging
to-report soil-multiplier-sources
  let report-string ""
  set report-string (word report-string
    "Harvest contributions: " soil-multiplier-mate "\n"
    "Tree contributions: " soil-multiplier-trees "\n"
    "Thinning contributions: " soil-multiplier-increment "\n")

  if table:length species-multipliers > 0 [
    set report-string (word report-string
      "Table total: " sum table:values species-multipliers "\n")
  ]

  set report-string (word report-string
    "Current total multiplier: " soil-multiplier "\n"
    "Average soil gain: " mean [soil-gain] of patches)

  ;; IMPROVED: Clean logging for status check
  log-soil-data "status_check" "soil_multiplier_sources_called" 0

  report report-string
end

to-report species-contributions
  let report-string ""
  let species-names ["Toona" "Cañafístola" "Lapacho" "Petiribí" "Anchico" "Araucaria" "Guatambú" "Grevillea" "Kiri"]

  let i 1
  foreach species-names [ species-name ->
    let contribution 0

    if table:has-key? species-multipliers i [
      set contribution table:get species-multipliers i
    ]

    set report-string (word report-string species-name ": " contribution "\n")
    set i i + 1
  ]

  ;; IMPROVED: Clean logging for status check
  log-soil-data "status_check" "species_contributions_called" 0

  report report-string
end




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to die-ilex
  if size < minimum-viable-size [die]
end

to die-tree
if size < minimum-viable-size [die]
end

to-report current-soil-gain
  report soil-gain
end

to-report current-soil-energy
  report soil-energy
end

to-report current-energy-plants
  report  mean [ et ] of turtles
end

to-report total-soil-multiplier-mate
  report  [round soil-multiplier-mate] of turtles
end

to-report total-soil-multiplier-trees
  report  [round soil-multiplier-trees] of turtles
end

to-report total-soil-multiplier
  report mean [soil-multiplier] of turtles
end

to-report cumulative-thinning-effect
  report mean [soil-multiplier-trees] of patches
end

to-report thinning-biomass-removed
  report sum [thinned-amount] of turtles
end

to-report total-biomass-removed
  report total-harvest +
         sum [harvest-trees] of turtles with [breed != species0]
end

to-report external-reposition
  report fertilizer-amount
end

to-report fertilizer-harvest-ratio
  ifelse total-harvest > 0 [
    report fertilizer-amount / total-harvest
  ] [
    report 0
  ]
end

to-report total-soil-gain
  report  [round soil-gain] of patches
end

to-report total-soil-energy
  report  mean [ soil-energy] of patches
end

to-report total-soil
  report  mean [ soil] of patches
end

to-report patches-soil-factor
  report mean [local-soil-factor] of patches
end

to-report total-energy-ilex
  report sum [energy-ilex] of species0
end

to-report avg-energy-ilex
  report total-energy-ilex / Ni
end

to-report total-energy-trees
  report (sum [energy-Toona] of species1 + sum [energy-Cañafístola] of species2 + sum [energy-Lapacho] of species3 + sum [energy-Petiribí] of species4 +
    sum [energy-Anchico] of species5 + sum [energy-Araucaria] of species6 + sum [energy-Guatambú] of species7 + sum [energy-Grevillea] of species8 + sum [energy-Kiri] of species9 )
end

to-report avg-energy-trees
  report total-energy-trees / Nt
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
851
652
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
0
210
0
210
1
1
1
ticks
30.0

BUTTON
33
14
96
47
setup
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
32
56
95
89
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

TEXTBOX
160
102
310
120
NIL
11
0.0
1

SWITCH
30
99
138
132
Idlabel?
Idlabel?
0
1
-1000

SLIDER
27
630
180
663
Fertility
Fertility
0
10000
8400.0
100
1
NIL
HORIZONTAL

PLOT
866
13
1096
175
state-of-soil
time
soil index
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"soil-index" 1.0 0 -6459832 true "" "plotxy ticks ( sum [soil-energy] of patches ) / ( N + 1 )"

MONITOR
865
233
976
278
avg-en-trees
avg-energy-trees
2
1
11

MONITOR
866
180
952
225
energy-trees
total-energy-trees
2
1
11

MONITOR
964
180
1039
225
energy-ilex
total-energy-ilex
2
1
11

MONITOR
987
233
1062
278
avg-en-ilex
avg-energy-ilex
2
1
11

MONITOR
869
608
1021
653
total-soil
total-soil
0
1
11

MONITOR
698
658
850
703
total-soil-energy
total-soil-energy
0
1
11

PLOT
866
288
1096
450
ilex-harvest
time
total-harvest
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"ilex-harvest" 1.0 0 -15040220 true "" "plot total-harvest"

SLIDER
27
591
180
624
reposition
reposition
0
200
40.0
5
1
NIL
HORIZONTAL

SLIDER
26
668
180
701
harvest-intensity
harvest-intensity
0
100
40.0
1
1
NIL
HORIZONTAL

MONITOR
210
658
363
703
total-soil-multiplier-mate
soil-multiplier-mate
4
1
11

MONITOR
373
658
527
703
total-soil-multiplier-trees
soil-multiplier-trees
4
1
11

MONITOR
537
658
606
703
total-soil-multiplier
total-soil-multiplier
2
1
11

MONITOR
610
658
689
703
total-soil-gain
soil-gain
0
1
11

MONITOR
867
454
953
499
total-harvest
total-harvest
0
1
11

MONITOR
869
506
954
551
current-energy-plants
current-energy-plants
2
1
11

MONITOR
969
454
1055
499
harvest-amount
harvest-amount
2
1
11

MONITOR
971
506
1055
551
system-growth-energy-uptake
growth-energy-uptake
2
1
11

MONITOR
869
557
955
602
rebalance-time-interval
last-rebalance
0
1
11

PLOT
221
172
421
322
total-soil-multiplier-trees
time
mult trees
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot soil-multiplier-trees "

PLOT
220
16
420
166
soil multiplier mate
time
mult ilex
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot soil-multiplier-mate "

PLOT
639
14
839
164
current-soil-gain
time
soil-gain
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot soil-gain"

PLOT
635
330
835
480
fertilizer reposition
time
ext
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot fertilizer-amount"

PLOT
221
330
421
480
system-growth-energy-uptake
time
energy-uptake
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot growth-energy-uptake"

PLOT
431
15
631
165
soil multiplier
time
soil mult
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot soil-multiplier"

PLOT
636
484
836
634
fertilizer-harvest-ratio
time
fertilzer / harvest
0.0
520.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot fertilizer-harvest-ratio"

PLOT
429
484
629
634
total-biomass-removed
time
biomass
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot total-biomass-removed"

PLOT
222
486
422
636
total-soil-energy
time
soil-energy
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot total-soil-energy"

SWITCH
28
553
167
586
minreposition?
minreposition?
1
1
-1000

PLOT
429
331
629
481
thinning-biomass-removed
time
thinning-biomass
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot thinned-amount"

CHOOSER
29
139
167
184
interaction-type
interaction-type
"no-interaction" "distance" "shade" "soil" "combined"
4

SWITCH
29
189
149
222
w-network?
w-network?
0
1
-1000

SWITCH
29
271
125
304
w-matrix?
w-matrix?
0
1
-1000

SWITCH
29
349
165
382
multi-network?
multi-network?
1
1
-1000

BUTTON
28
390
182
423
check-neighbor-distances
check-neighbor-distances
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
28
230
180
263
draw-w-network?
draw-w-network?
0
1
-1000

BUTTON
28
431
153
464
test-neighbors-1
test-neighbors-1
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
27
471
151
504
test-neighbors-2
test-neighbors-2
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
27
512
197
545
create-test-network-and-export
create-test-network-and-export
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
868
664
1020
697
export-node-coordinates
export-node-coordinates
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
28
310
159
343
w-matrix_xy?
w-matrix_xy?
0
1
-1000

MONITOR
971
557
1098
602
local-soil-factor
patches-soil-factor
0
1
11

@#$#@#$#@
MaxEn-WeightedMultiNetw5: Weighted Matrix with Time (ticks) and distance, soil, shade interactions working either independently or combined.
MaxEn-WeightedMultiNetw6: All previous but also recording (x,y) coordinates.


## WHAT IS IT?


This code is included as Supplementary Materials for the article "An Agent-Based Model of Inter-Species Interactions in Agroforestry Systems". We constructed a model defined over a field represented as an area of 210x210 pixels with 20x20 ilex paraguariensis plants and 20x20 consociations or near-neighbour interactions, one set of 4 interactions for each ilex plant with its 4 equidistant tree neighbours. For each of 9 species of trees there are 2x20 consociations with ilex paraguariensis, one set of 4 interactions for each tree with its 4 equidistant ilex plants. There is one control of 2x20 ilex paraguariensis in the absence of trees. The mate plants make a grid with positions {10, 20, 30…., 200} in both the x and y coordinates. The trees make a grid with positions {5, 15, 25…., 195, 205} on the x-axis, with each x-coordinate designating one tree species that makes a whole row with positions {5, 15, 25…., 195, 205} along the y-axis (a column). There are two columns for each tree species, with adjacent x coordinates. The last two columns at x 195 and 205 are empty of trees but contain ilex paraguariensis, designated as a row of mate not consociated with trees. This is the control. 

The distance between plants is 10 pixels, representing 1.5 meters in the actual experiment on the field. Thus, 1 meter is 6.67 pixels, and the NetLogo world represents an are of just over 1,000 squared meters. 

Summarizing, there are initially 20x20 = 400 plants of ilex paraguariensis of which 400-40 == 360 are consociated with trees, and 40 are not consociated with any tree. There are 42 trees of each species, making a total of 9x42 = 378 trees. The species are listed in the code, an acronym is used for compact id, and the species are numbered.

For ease of keeping track, these are the xy offsets for the creation of the 9 species of trees: to create-species 
[breed-name start-x start-y colour]
  let coordinates [[5 5] [5 15] [5 25] [5 35] [5 45] [5 55] [5 65] [5 75] [5 85] [5 95] [5 105] [5 115] [5 125] [5 135] [5 145] [5 155] [5 165] [5 175] [5 185] [5 195] [5 205]]

The x coordinate is creating adding 10 to the previous one iteratively, while the positions on the y axis are fixed.


The approach aims to use structured breed names, combined with flexible, parametrized agent creation, thus setting a strong foundation for a complex ecological or environmental simulation. This method enhances the modularity, readability, and scalability of the model, supporting detailed ecological dynamics and interactions. 

## HOW IT WORKS

The model simulates soil fertility dynamics and plant growth in an agroforestry system. Here's an overview of the key processes:

Soil Fertility and Energy:
- Soil fertility is categorized into five levels, each mapped to a 'soil factor' that modulates plant growth and energy dynamics.
- Plants extract energy from the soil to grow.
- Plants are harvested, and trees are prunned and thinned. The organic matters goes back to the soil.
- The model uses 'soil-energy' as a working variable to track changes before updating the main 'soil' variable.
- Energy flows between soil and plants, with plants depleting soil energy as they grow and returning energy through various processes.

Each species starts with a default energy, and each soil quality endows the plants with a given energy. The growth rate of all plants depends on the soil quality and the species. Their growth rate is modelled from measured allometric data from the experiment in 2014 and 2015, referenced in the manuscript. The available photosynthetic available radiation (PAR) was measured in 2018, and it is useful here as a control to verify that the competition assigned to consociations scales with field experiments.

Cañafístola	1,33
Anchico 	1,32
Lapacho 	1,49
Loro negro	1,44
Araucaria	1,25
Guatambú	1,56
Toona 	        1,64
Grevillea 	1,35
Kiri	        1,54

There are direct and indirect interactions between agents. As trees grow, their shade competes the growth of ilex plants directly, occluding and causing a decrease in their rate of growth. Trees are trimmed, and the branches decompose in the soil increasing the fertility. The same happens with the remnants of the harvest. When tree density is thinned, the logs remain in the ground as well. These are the endogenous sources of organic matter, which have small differences across species. The availability of added, exogenous, fertilizers is enhanced by the amount of organic matter in the soil. These second order effects are one type of indirect interaction between agents. Each tree species also causes changes in soil micronutrients. For instance, we have measured different soil contents of Phosphorous for each species. These are another source if indirect interaction between agents.

ENERGY: SOIL GROWTH HARVEST TREES FERTILIZATION 

The user chooses a soil Fertility level within 5 categories. These are arbitrary numbers, but what matters is the ratios between changes in soil resources caused by different processes. 

During Set-Up, the chosen starting Fertility is transferred to a Soil variable called simply "soil_i", i=1,2,3,4,5 for the 5 categories: set soil_i fertility

One of the objectives of implementing an agroforestry system is to restore the soil mainly through the recovery of soil organic matter (SOM). Trees are trimmed and thinned (or prune) and left to decompose in-situ. In addition different species of trees cause different changes in elemental composition and micronutrients, most likely through specific associations with funghi and microorganisms. Organic matter is also contributed by the harvest of ilex, as a percentage of the trimmed plants is left on the ground.

We declare as Global variables : Globals [....soil-multiplier-mate soil-multiplier-trees soil-multiplier soil-gain]

These soil multipliers contribute directly to the "soil energy" or richness of the soil as a "soil-gain" which is computed as a proportion of the total carbon-rich mass produced. This organic matter also buffers the pH of the soil and directly increaes the proportion of externally added fertilizers available to plants.

We declare as field variables, patches-own [....soil soil_i (i,1,..5) soil-energy.....]

The soil value chosen during Set-Up, the chosen starting Fertility, is later transferred to Soil and this value is updated to account for the different contributions.

Each soil fertility level or category is mapped onto a soil factor which will be used to modulate the growth rate of ilex and trees, their capacity to take "energy" from the soil, and the volume produced as harvest, trimming, and thinning, closing the loop. If the system is working soil fertility will slowly increase with time. 

The following is the sequence of events that updates the soil.

Set-Up Stage:
1. User selects an initial Fertility level.
2. The chosen value is stored as 'soil' and categorized into one of five 'soil_i' types.
3. Growth rates for agents are defined, agents are created, and variables (e.g., energy levels, soil multipliers) are initialized.

●User chooses a starting Fertility level
●Set-up stores the chosen value as "soil" and as a soil type: "soil_i", i=1,...5
(the starting fertility is mapped to variables soil and soil_i, i=1,...5)
●All plants are created and distributed on the field.
●The growth rate values for the agents are defined.
●The variables for iterative simulations are initialized, such as energy leves and soil multipliers from harvest, prunning, and thinning.
●The timing is established for growth, harvesting, fertilizing, trimming, and thinning.

Simulation: To-Go
●set-soil-factor
 Each category of soil is mapped to a multiplier, the variable "soil-factor". 

●energy-account
   - Uses "soil-energy" as a working variable to track soil changes (facilitates debugging).
   - Maps "soil" value to "soil-energy".
   - Assigns energy values to plants based on soil type and soil-factor using "et" (energy trees).
   - Plants grow by depleting soil energy.
   - Harvesting, trimming, and thinning partially deplete plant energy.
   - These processes return carbon-rich matter to the soil, gradually improving soil quality.

With these values ilex plants and trees start to grow using part of the energy of the soil, that is depleting the soil, while their energy is partially depleted by the interventions of harvesting, trimming, and thinning. This recursion in the sizes of the plants result in carbon-rich matter being added back to the soil, which needs to be accounted for until they update the value of "soil-energy" and "soil". This process is not instantaneous. As the soil changes, the energy assigned to plants is reset and that takes care of the cycle in a simplified version.

Energy Cycle:
- Plants deplete soil energy through growth.
- Interventions of harvesting, trimming, and thinning, take some energy away.
- Management practices (harvesting, trimming, thinning) return organic matter to soil.
- Changes in soil quality lead to recalibration of plant energy assignments.
- This cycle is simplified in the model, acknowledging that in reality, the process is not instantaneous.

The model aims to capture the complex interactions between plants and soil in an agroforestry system, demonstrating how management practices can lead to sustainable improvement in soil fertility over time.


●To Grow

The grow procedure simulates the growth of all plant species in the model. Growth rates are the experimental allometric parameters, and are multiplied by the soil-factor that determines the condition:

1. For each species (species0 to species9):
   - Calls grow-at-rate with the species-specific growth rate
   - grow-at-rate increases the size of each plant based on its growth rate and the soil factor:
     size = size * (1 + growth_rate) * soil_factor

2. Calculates total energy uptake for growth:
   growth-energy-uptake = (et * Ni + et * Nt) / 3
   Where:
   - et: energy available to trees
   - Ni: number of ilex plants
   - Nt: total number of trees

3. Reduces soil energy based on growth energy uptake:
   Each patch's soil-energy is decreased by growth-energy-uptake


ask turtles grow-at-rate-variable
record the energy uptake as growth-energy-uptake

The soil is asked to loose the energy taken by the trees and ilex: 
ask patches set soil-energy (soil-energy - growth-energy-uptake)

●harvest
The harvest procedure simulates the periodic harvesting of Ilex (yerba mate) plants in the agroforestry system. 
Harvesting occurs at predefined intervals, set during the setup:
[24 76 128 180 232 284 336 388 440 492 544]
These represent ticks (time steps) when harvesting takes place, with the first harvest at tick 24 (June of the first year) and subsequent harvests every 52 ticks (annually).

The To-Harvest-Ilex and To-Harvest-Mate reduce the size of ilex plants by the percentage chosen in harvest-inensity. Standard practice in this experimental lot is 33%. Ilex plants loose a 1.21xPlant Reduction of their energy.

The size reduction in ilex plants is the harvest-amount. Total harvest stores this value summed over all ilex plants. Approximately 15% of this harvest amount remains in the soil and is mapped/stored in "soil-multiplier-mate", which is added to "soil-multiplier". The sum over all ilex of this 15% of the harvest amount becomes a "soil-gain-mate", which is added to "soil-energy". Soil-energy is updated.

Key Points
1. Only Ilex plants above a certain size (harvest-size) are harvested.
2. The harvest reduces both the size, by a chosen percentage (harvest-intensity, usually 33%), and energy of harvested ilex plants by 40%.
3. A portion of the harvest (15%) contributes to soil organic matter, improving soil quality.
        - This is tracked in "soil-multiplier-mate"
   	- Added to the overall "soil-multiplier"
        -  Calculating "soil-gain-mate" as the sum of this 15% contribution from all ilex plants
        -  Updating soil-energy by adding soil-gain-mate
4. The procedure accounts for both the economic output (total-harvest) and the ecological impact (soil improvement) of harvesting.
5. Harvesting occurs at regular intervals, simulating annual harvests.


●fertilizing

The fertilizing procedure simulates the periodic addition of external nutrients to the soil. This process is crucial in agriculture to replenish soil nutrients and maintain soil fertility.

Timing:
Fertilization occurs at predefined intervals, set during the setup:
[40 92 144 196 248 300 352 404 456 508 560]
These numbers represent ticks (time steps) when fertilization takes place, with the first application at tick 40 (October of the first year) and subsequent applications every 52 ticks (annually).

When fertilization occurs, the following steps are executed:

1. Calculation of Fertilizer Amount:
   fertilizer-amount = (reposition / 100) * growth-energy-uptake * 1
   fertilizers-solubility  soil-multiplier * buffer-factor

   Where:
   - reposition: User-defined percentage of energy to be replenished
   - growth-energy-uptake: Energy consumed by plants during growth
   - the SOM produce as soil-multiplier increases fertilizers availability to plants

2. Soil Gain Calculation:
   soil-gain = fertilizer-amount * ( 1 + 1 * fertilizers-solubility)  

   This calculation accounts for the enhancing effect of soil organic matter (represented by soil-multiplier) on fertilizer efficiency.

3. Soil Energy Update:
   For each patch:
   soil-energy = soil-energy + soil-gain

A switch "minreposition" can be used to choose fix or adjustable reposition. If minreposition? = True, the reposition is scaled back when soil improvements increases beyond 40%. If the soil improvement is better than 40%, then reposition is decrased: soil-energy-improvement > 1.4 [ set reposition max list (reposition * 0.8) 10            ]  

Key Points:
- The fertilizer amount is based on a percentage (reposition) of the energy consumed by plants during growth.
- The effectiveness of the fertilizer is doubled by the soil's organic matter content (soil-multiplier).
- This simulates how organic matter improves nutrient retention and availability.
- The procedure allows for dynamic adjustment of soil fertility based on plant growth and management practices.
- It represents a simplified version of the complex nutrient cycling processes in agroforestry systems.
- Fertilization occurs at regular intervals, simulating annual applications.

●trimming

The trimming procedure simulates the periodic pruning of trees branches in the agroforestry system, to reduce their crowns and incorporate material to the soil. 

Trim factors are chosen conmensurate with the growth rates. Their product is one, meaning we trim more trees that grow more.

Trimming occurs at predefined intervals, set during the setup:
[36 88 140 192 244 296 348 400 452 504 556]
These represent ticks (time steps) when trimming takes place, with the first trim at tick 36 (September of the second year) and subsequent trims every 52 ticks (annually).

1. Trimming Calculation:
   - Each species has a specific trim factor (ranging from 0.61 to 0.8)
   - These factors are chosen to balance with growth rates 
   - For each tree:
     * harvest-trees = size * (1 - trim-factor)
     * New size = size * trim-factor
     * Energy is reduced by 0.3 * et * 1
2. Soil Organic Matter Contribution:
   - 20% of the trimmed material (harvest-trees * 0.2) contributes to the species-specific soil multiplier
   - These contributions are summed across all species
3. Soil Update:
   The update-soil-multipliers-trimm procedure is called to:
   - Update soil-multiplier-trees with the total contribution from all species
   - Update the overall soil-multiplier
   - Calculate soil-gain for each patch (soil-multiplier-trees * Nt)
   - Increase soil-energy of each patch

Trim-factors: [0.7 0.6 0.74 0.72 0.8 0.78 0.76 0.8 0.68] 
These factors, when multiplied by their respective growth rates, equal 1, ensuring a balanced management approach across different tree species.

Key Points:
- Different tree species are trimmed at different rates, reflecting their growth characteristics
- Trimming reduces both the size and energy of trees
- A significant portion (20%) of trimmed material contributes to soil organic matter, improving soil quality
- The procedure accounts for both the management of tree growth and the ecological impact (soil improvement) of trimming
- Trimming occurs at regular intervals, simulating annual management practices


●thinning

The thinning procedure simulates the selective removal of trees in the agroforestry system to manage density and promote the growth of remaining trees. This process occurs in two phases and contributes significantly to soil organic matter.  One every other tree with a size larger than 9 is cut down to size 1.

Setup:
- thiniter1?: Initially set to true, indicates the first thinning phase is ready
- thiniter2?: Initially set to false, indicates the second thinning phase is not yet ready
- thinned-count: Tracks the number of trees thinned in each operation

Approximately 15% of the mass of trees cut down becomes soil-multiplier-trees. The trees are counted, and the total soil-multiplier-trees summed over all reduced trees is mapped to soil-gain, which is added to soil-energy. Soil-multiplier-trees is the increment in the value of soil-multiplier which is updated. 

Process:
The thinning occurs in two alternating phases, each targeting different rows of trees:
1. Thinning Operation (perform-thinning):
   - Targets trees with size > 12   
   - Reduces the size of targeted trees to 1.0
   - Counts the number of thinned trees
2. Thinning Phase 1 (thinning1):
   - Targets trees at y-coordinates: 5, 25, 45, ..., 205
   - Adds 0.75 to soil-multiplier (representing ~9-10% of thinned biomass becoming soil organic matter)
   - Records the current tick count (countert1)
   - Switches to phase 2 for the next thinning operation
3. Thinning Phase 2 (thinning2):
   - Targets trees at y-coordinates: 15, 35, 55, ..., 215
   - Adds 0.75 to soil-multiplier
   - Switches back to phase 1 for the next thinning operation
4. Soil Update (update-soil-multipliers):
   - Increases soil-multiplier-trees by the increment (0.75)
   - Updates overall soil-multiplier
   - Calculates soil-gain for each patch (soil-multiplier-trees * thinned-count)
   - Increases soil-energy of each patch
Key Points:
- Thinning is triggered dynamically based on tree growth (size >= 9) rather than at fixed intervals
- The process alternates between two phases, ensuring even distribution of thinning across the plantation
- There's a minimum interval of 78 ticks between the first and second thinning phases
- Thinning targets mature trees in alternating rows across the simulation area
- The process significantly contributes to soil organic matter, improving soil quality
- Thinning helps manage tree density, promoting better growth conditions for remaining trees
Monitoring:
- current-soil-gain: Reports the most recent gain in soil organic matter from thinning
- current-soil-energy: Reports the current soil energy level, which increases after thinning operations


●Shade Competition
The shade competition procedure simulates the effect of tree shading on Ilex paraguariensis (yerba mate) plants in the agroforestry system, reflecting how larger trees can directly impact the growth of smaller plants beneath them. 

The compete-shade procedure is called in each GO cycle and affects only species0 (Ilex paraguariensis):
1. Neighbor Identification:
   - For each Ilex plant, identify all neighboring trees within a radius of 7.5 units.
   - Select up to 4 closest neighbors. If fewer than 4 neighbors are within range, all available neighbors are considered.
2. Size Comparison:
   - Calculate the average size of the selected neighboring trees.
3. Growth Adjustment:
   - If the average size of neighboring trees is greater than 9:
     * Reduce the size of the Ilex plant by a shade factor that can not be greater than 0.5: shade-factor max (list (1 - (avg-size / 30) ^ 2)  0.5), or
     * Reduce the size of the Ilex plant by 10% (multiply size by 0.9)
   - If the average size of neighboring trees is 9 or less:
     * Allow normal growth for Ilex plants 
Key Points:
- Only Ilex paraguariensis (species0) is directly affected by shade competition.
- The procedure models the shading effect of larger trees on understory crops.
- A maximum of 4 closest neighbors are considered to limit computational complexity while still capturing local effects.
- The size threshold of 9 for neighboring trees represents a critical point where shading becomes significant.
- The 10% size reduction for Ilex under large trees simulates reduced growth due to shade.
- Ilex plants under smaller trees (average size ≤ 9) can grow normally.

Ecological Implications:
- This procedure captures the trade-off in agroforestry systems between beneficial effects of trees (e.g., soil improvement) and their competitive effects (shading).
- It reflects the dynamic nature of plant interactions in multi-strata agroforestry systems.
- The model assumes that larger trees (size > 9) create significant shade that impacts understory crops.

Note: The specific values (radius of 7.5, size threshold of 9, 10% reduction) are parameters that can be adjusted based on field observations or to test different scenarios.


●Update Soil

The soil update procedure simulates the gradual incorporation of organic matter into the soil and the long-term changes in soil quality within the agroforestry system. This process represents the complex, time-dependent dynamics of soil organic matter decomposition and nutrient cycling.
Timing:
The rebalance-soil procedure is called every 26 ticks (approximately 6 months in the model's time scale):
if ticks > 1 and ticks mod 26 = 0 [rebalance-soil]

1. Organic Matter Decomposition:
   - Every 52 ticks (annually), the soil-multiplier is halved:
     if ticks mod 52 = 0 [set soil-multiplier soil-multiplier * 0.5]
   - This represents an approximate 1-year half-life for soil organic matter

The degradation of all carbon-rich sources and their incorporation to the soil is a slow gradual process that takes time. This "non-binary" source of complexity is simplified in the model with a periodic rebalancing of the soil every six months.

to rebalance-soil mappes the value of soil-energy to soil, and finds which of the 5 categories of soil this corresponds to. The color display is updated. 
The reports "total-soil" and "total-soil-energy" display per-patch values and the "state-of-soil" icon displyes the evolution of soil-energy. The changes in energy-ilex and energy-trees are reported.

Process:
1. Organic Matter Decomposition:
   - Every 52 ticks (annually), the soil-multiplier is halved:
     if ticks mod 52 = 0 [set soil-multiplier soil-multiplier * 0.5]
   - This represents an approximate 1-year half-life for soil organic matter
2. Soil Energy Update:
   - The current-soil-energy value is mapped to the soil variable for each patch
   - This represents the incorporation of accumulated organic matter and nutrients into the soil
3. Soil Classification:
   The soil is reclassified into one of five categories based on its new energy value:
   - soil1 (Highest quality): soil >= 8000
   - soil2: 6000 <= soil < 8000
   - soil3: 4000 <= soil < 6000
   - soil4: 2000 <= soil < 4000
   - soil5 (Lowest quality): soil < 2000
4. Visual Update:
   - The color of each patch is updated to reflect its new soil category:      soil1: pcolor 49 (dark green);      soil2: pcolor 39 (medium green);      soil3: pcolor 29 (light green);      soil4: pcolor 19 (yellowish);      soil5: pcolor 139 (brownish)
Key Points:
- The procedure simulates the gradual nature of organic matter decomposition and incorporation into the soil
- It reflects the concept that soil improvement is a slow, cumulative process
- The model simplifies complex soil dynamics by updating soil quality at regular intervals
- The visual representation allows for easy tracking of soil quality changes across the simulated area
Monitoring:
- total-soil: Reports the current soil quality values for each patch
- total-soil-energy: Reports the current soil energy values for each patch
- state-of-soil: A plot showing the evolution of soil energy over time
- Changes in energy-ilex and energy-trees are also reported, reflecting the impact of soil quality on plant growth
Ecological Implications:
- This procedure captures the long-term impacts of agroforestry practices on soil quality
- It demonstrates how various management practices (harvesting, trimming, thinning) contribute to soil improvement over time
- The visual representation helps in understanding the spatial distribution of soil quality improvements

Note: The specific values for soil categories and update intervals are parameters that can be adjusted based on field observations or to test different scenarios. The simplification of soil dynamics into discrete update events and categories allows for computational efficiency while still capturing the essential trends in soil quality change.




## HOW TO USE IT

Items in the Interface tab

1. Fertility Slider:
   - Range represents different soil qualities, classified into 5 soil types.
   - Interesting to observe restoration of lower fertility levels as the system evolves.
   - Each soil quality determines growth rates for plants.

2. Idlabel Switch:
   - Adds species number to each plant for easy identification.
3. Network Switch:
   - Creates linkages between ilex plants and their 4 closest trees.
   - Link colors correspond to the linked trees' colors.
4. Matrix Dropdown:
   - Creates an adjacency matrix for the network of near neighbors to each ilex plant.
   - Two options available for future development of more complex interactions.

5. State-of-soil Plot:
   - Reports the "energy" or fertility state of the soil over time.
   - Initial state set by "Fertility" slider.
   - Shows how soil changes due to plant uptake, pruning, thinning, and natural processes.
6. Energy-trees Monitor:
   - Reports available energy for plant growth.
   - Reflects soil state through "soil-factor" value.
7. Energy Plot:
   - Shows the complex flow and balance of nutrients in the system.
   - Represents soil resources uptake by plants and feedback from organic matter.
8. Harvest-intensity Slider:
   - Sets the percentage of ilex plants harvested.
9. Reposition Slider:
   - Determines the amount of fertilizer added during fertilization events.

The state of the soil, or soil energy, or soil value within this classification in 5 soil types for the dynamic range chosen in Fertility, is also mapped to a "soil-factor" value to simplify operations. We use the soil-factor value to modulate the energy available to the plants and the growth of the plants. 

ENERGY

The flow and balance of nutrients can be very complex, with multiple interconnected variables. Nutrients represent the available resources of the soil for uptake by the plants, it provides them the energy to grow. The reincorporation to the soil of tree branches and trunks feeds back to the soil and add nutrients both directly and indirectly. 

## THINGS TO NOTICE

1. Soil Quality Changes:
   - Observe how soil color changes over time, reflecting fertility improvements or degradations.
2. Plant Growth Patterns:
   - Notice differences in growth rates between ilex and different tree species.
   - Observe how plant sizes change after harvesting, trimming, and thinning events.
3. Shade Competition:
   - Look for areas where ilex plants grow slower due to shading from larger trees.
4. Soil Energy Fluctuations:
   - Watch how soil energy changes after major events like harvesting, trimming, and fertilizing.
5. Network Dynamics:
   - If network view is on, observe how connections between ilex and trees change as plants grow or are removed.
6. Species Distribution:
   - Notice how the distribution of different tree species affects the overall system dynamics.


## THINGS TO TRY

1. Fertility Experiments:
   - Run simulations with different initial fertility levels and compare long-term outcomes.
2. Harvest Intensity:
   - Adjust the harvest-intensity slider and observe its impact on ilex growth and soil quality.
3. Fertilization Strategies:
   - Modify the reposition value to simulate different fertilization intensities.
   - Compare aggressive vs. conservative fertilization strategies.
4. Species Balance:
   - Try removing or adding certain tree species and observe the effect on system dynamics.
5. Management Timing:
   - Experiment with different timings for harvesting, trimming, and thinning operations.
6. Climate Scenarios:
   - If implemented, test the model under different simulated climate conditions.
7. Long-term Simulations:
   - Run the model for extended periods to observe long-term trends in soil quality and plant growth.
8. Spatial Patterns:
   - Analyze how initial planting arrangements affect long-term system development.
9. Optimization Challenge:
   - Try to find the optimal balance of harvesting, fertilizing, and tree management for sustainable high yields.



## EXTENDING THE MODEL

Shannon Entropy
to-report calculate-shannon-entropy let plant-sizes [size] of turtles let size-counts table:make foreach plant-sizes [ size -> table:put size-counts size (table:get-or-default size-counts size 0 + 1) ] let probabilities map [ count -> count / length plant-sizes ] table:values size-counts report -1 * sum (map [ p -> p * log p 2 ] probabilities) end
Focusing on quantifying the complexity and information content of the agroforestry system as it evolves over time is an interesting approach. This can provide valuable insights into the system's dynamics and help validate the model's behaviour. Here are some ways one could approach this:
1.	Shannon Entropy: 
        Calculate the Shannon entropy of the system at each time step.
        This could be based on the distribution of plant sizes, soil qualities, or species abundances.
        Increasing entropy over time might indicate growing complexity or diversity.
2.	Species Diversity Indices: 
 	Implement measures like Simpson's Diversity Index or Shannon-Wiener Index.
 	These can quantify the biodiversity of your agroforestry system over time.
3.	Spatial Complexity Measures: 
 	Use metrics like Moran's I or Geary's C to quantify spatial autocorrelation.
 	This can help track how the spatial arrangement of plants changes over time.
4.	Information Theoretic Measures: 
 	Implement mutual information calculations between different components (e.g., soil quality and plant growth).
 	This can reveal how different parts of the system influence each other over time.
5.	Network Analysis: 
 	If your model includes interactions between plants, construct and analyze network metrics over time.
 	Measures like degree distribution, clustering coefficient, or centrality can quantify system complexity.
6.	Fractal Dimension: 
 	Calculate the fractal dimension of the spatial distribution of plants or soil qualities.
 	This can provide insights into the system's spatial complexity.
7.	Predictability Measures: 
 	Implement methods to quantify the predictability of the system state over time.
 	This could involve time series analysis techniques or Lyapunov exponents.
8.	State Space Analysis: 
  	Track the system's trajectory in a defined state space (e.g., total biomass vs. soil quality).
 	Analyze the properties of this trajectory (e.g., attractor characteristics).
To implement these in NetLogo, we would need to:
1.	Define the relevant system states or variables to track.
2.	Implement the calculation of these measures at each time step or at regular intervals.
3.	Store and visualize the evolution of these complexity measures over time.



## NETLOGO FEATURES

- Use of breed-specific variables to model different tree species characteristics
- Implementation of a complex soil quality system using patch variables
- Dynamic linking of agents to create a network representation of plant interactions
- Use of the 'runresult' primitive to dynamically execute breed-specific code
- Custom reporters for calculating various system metrics (e.g., energy levels, harvest amounts)
- Use of the 'foreach' command with complex lists to manage periodic events (harvesting, fertilizing, etc.)

## RELATED MODELS


- "Rabbits Grass Weeds" - A simple ecosystem model demonstrating plant-animal interactions
- "Plant Growth" - Simulates basic plant growth patterns
- "Erosion" - Models soil erosion processes, which could be relevant to soil quality dynamics
- "Firefighters" - While not directly related, it demonstrates spatial management strategies that could be analogous to forest management
- "Scatter" - Useful for understanding how to distribute agents in space, which is relevant to tree planting strategies
- "Heatbugs" - Demonstrates how agents can affect and be affected by their local environment, similar to how trees interact with soil in your model

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)

DISCUSSION 

Realistic Scaling: The model incorporates field measurements for growth rates and photosynthetic available radiation, ensuring that the relative sizes and competition levels between species are accurately represented. This is crucial for the model's validity and predictive power.
2. Organic Matter Dynamics: The model accounts for the conversion of trimmed plant material into Soil Organic Matter (SOM), including the effects of harvesting and thinning. The rapid decay of this organic matter due to environmental factors like extreme weather is also considered, which attempts to add an important layer of realism.
3. Soil Quality Representation: While the five levels of soil quality are arbitrary, the relative scaling and evolution attempt to capture observed reality. This simplification allows for clearer visualization of system behaviour.
4. Local Effects: The model captures local variations in soil quality, competition, and plant growth, which is crucial for understanding the complex interactions between trees, ilex plants, and soil conditions. This localized approach is a strength of the model.
5. Comparative Analysis: The inclusion of a control lot without trees provides a valuable baseline for comparison with tree-integrated systems.
6. External Inputs: The model allows for the exploration of different levels of external fertilizer inputs, scaled as a percentage of harvested matter replacement. This feature enables the investigation of various management strategies.
7. Complex Interactions: The model successfully represents multiple layers of concatenated causes and effects, which would be difficult to predict without computational modelling.
8. Limitations: Many interactions (e.g., those involving microbial communities, fungi, insects, and birds) are not represented in the current model. This transparency about the model's scope is important and should underpin future efforts at constructing more realistic ones.
The model attempts to provide a first tool for exploring the complex dynamics of agroforestry systems, particularly focusing on ilex production. The attention to realistic scaling and local effects is a starting point for additional measurements and the incorporation of more relevant interactions.
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
NetLogo 6.2.2
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
