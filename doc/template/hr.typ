//! Support for Croatian datetime formatting.

/// Gramatical case is either an index into or a value from this array.
#let hr-cases = (
  ("n", "nominativ", "nominative"),
  ("g", "genitiv", "genitive"),
  ("d", "dativ", "dative"),
  ("a", "akuzativ", "accusative"),
  ("v", "vokativ", "vocative"),
  ("l", "lokativ", "locative"),
  ("i", "instrumental"),
)
/// Gramatical count is either an index into or a value from this array.
#let hr-counts = (
  ("jed", "jednina", "singular"),
  ("množ", "množina", "plural"),
)
/// Gramatical gender is either an index into or a value from this array.
#let hr-genders = (
  ("m", "muški", "masculine"),
  ("ž", "ženski", "feminine"),
  ("s", "srednji", "netural")
)

#let _word-index(lookup, word) = {
  if type(word) == int {
    return word
  }
  if type(word) != str {
    panic("word must be an `int` or `str`")
  }
  let word-lower = lower(word)
  for (i, it) in lookup.enumerate() {
    for match in it {
      if word-lower == match {
        return i
      }
    }
  }
  panic("unknown index of: " + name)
}

#let hr-parse-case(name) = _word-index(hr-cases, name)

/// Names of each month for each gramatical case
#let hr-month-names = (
  // N         G            D            A            V            L            I
  ("siječanj", "siječnja",  "siječnju",  "siječnja",  "siječnje",  "siječnju",  "siječnjem"),
  ("veljača",  "veljače",   "veljači",   "veljaču",   "veljačo",   "veljači",   "veljačom"),
  ("ožujak",   "ožujka",    "ožujku",    "ožujak",    "ožujče",    "ožujku",    "ožujkom"),
  ("travanj",  "travnja",   "travnju",   "travanj",   "travnju",   "travnju",   "travnjem"),
  ("svibanj",  "svibnja",   "svibnju",   "svibanj",   "svibnju",   "svibnju",   "svibnjem"),
  ("lipanj",   "lipnja",    "lipnju",    "lipanj",    "lipnju",    "lipnju",    "lipnjem"),
  ("srpanj",   "srpnja",    "srpnju",    "srpanj",    "srpnje",    "srpnju",    "srpnjem"),
  ("kolovoz",  "kolovoza",  "kolovozu",  "kolovoz",   "kolovoze",  "kolovozu",  "kolovozom"),
  ("rujan",    "rujna",     "rujnu",     "rujan",     "rujne",     "rujnu",     "rujnom"),
  ("listopad", "listopada", "listopadu", "listopad",  "listopade", "listopadu", "listopadom"),
  ("studeni",  "studenoga", "studenomu", "studeni",   "studeni",   "studenomu", "studenim"),
  ("prosinac", "prosinca",  "prosincu",  "prosinac",  "prosinče",  "prosincu",  "prosincem"),
)

#let hr-month-name = (month, case: 0) => {
  if type(month) != int or month < 1 or month > 12 {
    panic("month must be an integer in range [1, 12]")
  }
  let used-case = hr-parse-case(case)
  hr-month-names.at(month - 1).at(used-case)
}

#let hr-date-format = (date, format) => {
  if format != "[day]. [month repr:long] [year]." {
    panic("date formatting not supported for croatian")
  } else {
    [#date.day(). #hr-month-name(date.month(), case: "G") #date.year().]
  }
}

#let locale-date-format = (locale, date, format: none) => {
  if locale == "hr" {
    let used-format = if format != none {
      format
    } else {
      "[day]. [month repr:long] [year]."
    }
    return hr-date-format(date, used-format)
  } else if locale == "en" {
    let used-format = if format != none {
      format
    } else {
      "[day] [month repr:short] [year]"
    }
    return date.display(used-format)
  } else {
    panic("unhandled locale-date-format locale: " + locale)
  }
}

#let _hr-nouns = json("hr_nouns.json")

#let word-root-transform(word, language: "hr", count: 0, gender: none, case: 0) = {
  if language == "hr" {
    let forms = _hr-nouns.at(word, default: none)
    if forms == none {
      panic("word '" + word + "' not in dictionary")
    }
    let used-count = if count != none {
      if type(count) == int {
        hr-counts.at(calc.min(count, 1)).last()
      } else if type(count) == str {
        let count_i = _word-index(hr-counts, count)
        hr-counts.at(count_i).last()
      } else {
        panic("invalid (gramatical) `count` argument")
      }
    } else {
      "singular"
    }
    let used-gender = if gender != none {
      if type(gender) == str {
        _word-index(hr-genders, gender)
      } else if type(gender) == int {
        gender
      } else {
        panic("invalid (gramatical) `gender` argument")
      }
    } else {
      forms.at("gender")
    }
    let used-case = if case != none {
      if type(case) == str {
        _word-index(hr-cases, case)
      } else if type(case) == int {
        case
      } else {
        panic("invalid (gramatical) `case` argument")
      }
    } else {
      0
    }
    (forms.at(used-count).at(used-gender).at(used-case),)
  } else {
    panic("language not supported")
  }
}

#let _name-exceptions = json("hr_name.json")

#let get-name-gender(name, locale: "hr") = {
  let (name-only, pretty-name) = if name.contains(",") {
    let parts = name.split(",").map(it => it.trim())
    (lower(parts.at(1)), parts.at(1) + " " + parts.at(0))
  } else {
    let trimmed = name.trim()
    (lower(trimmed.split(" ").at(0)), trimmed)
  }

  if locale == "hr" {
    // Female names almost always end in '-a', with some exceptions for
    // masculine names (e.g. "Luka" ~ en. "Luke").
    let letter-indicator = name-only.ends-with("a")
    if letter-indicator {
      if _name-exceptions.at(0).contains(name-only) { // m
        if _name-exceptions.at(1).contains(name-only) { // f
          return (2, pretty-name) // both masc and fem name
        }
        return (0, pretty-name)
      } else {
        return (1, pretty-name)
      }
    } else {
      if _name-exceptions.at(0).contains(name-only) { // m
        if _name-exceptions.at(1).contains(name-only) { // f
          return (2, pretty-name) // both masc and fem name
        }
        return (0, pretty-name)
      } else {
        return (0, pretty-name)
      }
    }
  } else {
    panic("name gender inference for '" + locale + "' locale not supported")
  }
}

#let get-name-count-gender(name, locale: "hr") = {
  let handle-list(names, locale) = {
    let pretty-names = ()
    let (first, first-pretty) = get-name-gender(names.at(0), locale: locale)
    pretty-names.push(first-pretty)
    for other in names.slice(1) {
      let (current, current-pretty) = get-name-gender(other, locale: locale)
      pretty-names.push(current-pretty)
      if current == none {
        continue
      }
      if first == none {
        first = current
        continue
      }
      if current != first {
        first = 2 // different genders, return neutral
      }
    }
    (1, first, pretty-names)
  }

  if type(name) == array {
    handle-list(name, locale)
  } else  if type(name) == str {
    if name.contains(" AND ") {
      let names = name.split(" AND ")
      handle-list(names, locale)
    } else{
      let (gender, name-pretty) = get-name-gender(name, locale: locale)
      (0, gender, (name-pretty,))
    }
  } else {
    panic("name(s) must be an `array` or `str`; got: " + type(name))
  }
}
