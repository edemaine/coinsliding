#if Puzzles.find().count() == 0
for family, font of fonts
  for char1 of font
    for char2 of font
      continue if char1 == char2
      puzzle = "#{char1}-#{char2}"
      unless Puzzles.findOne(
        family: family
        puzzle: puzzle
      )
        Puzzles.insert
          family: family
          puzzle: puzzle
