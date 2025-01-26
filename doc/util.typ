#let hr-month-name = (month) => {
  if month == 1 {"siječnja"}
  else if month == 2 {"veljače"}
  else if month == 3 {"ožujka"}
  else if month == 4 {"travnja"}
  else if month == 5 {"svibnja"}
  else if month == 6 {"lipnja"}
  else if month == 7 {"srpnja"}
  else if month == 8 {"kolovoza"}
  else if month == 9 {"rujna"}
  else if month == 10 {"listopada"}
  else if month == 11 {"stodenog"}
  else if month == 12 {"prosinca"}
  else { panic("invalid month") }
}

#let hr-date-format = (date) => [#date.day(). #hr-month-name(date.month()) #date.year().]

#let locale-date-format = (locale, date) => {
  if locale == "hr" {
    return hr-date-format(date)
  } else {
    panic("unhandled locale-date-format locale: " + locale)
  }
}

#let complexity(case: "worst", value) = {
  if case == "same" {
    $Theta(#value)$
  } else if case == "worst" {
    $O(#value)$
  } else if case == "best" {
    $Omega(#value)$
  } else {
    panic("unknown complexity case: " + case + "; valid values are: 'same', 'worst', 'best'")
  }
}
