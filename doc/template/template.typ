#import "@preview/wordometer:0.1.4": *

#import "hr.typ": locale-date-format, word-root-transform, get-name-count-gender
#import "outline.typ": custom-outline

#let _default-logo = image(
  "./FIDIT-logo.png",
  height: 15.15mm
)

#let _min_summary_words = 100
#let _max_summary_words = 400

#let _map-kind-name(name, locale: "hr") = {
  let lower-name = lower(name)
  if type(name) == "content" {
    return ("seminar", name)
  } else if type(name) == str {
    let pretty-name = if locale == "hr" {
      "Seminarski rad"
    } else if locale == "en" {
      "Seminar"
    } else {
      "Seminarski rad"
    }
    if lower-name == "seminar" or lower-name == "seminarski" or lower-name == "seminarski rad" {
      return ("seminar", pretty-name)
    } else if lower-name == "završni" or lower-name == "završni rad" or lower-name == "bacc" or lower-name == "bachelors" {
      let pretty-name = if locale == "hr" {
        "Završni rad"
      } else if locale == "en" {
        "Bachelor's Thesis"
      } else {
        "Završni rad"
      }
      return ("bachelors", pretty-name)
    } else if lower-name == "diplomski" or lower-name == "diplomski rad" or lower-name == "masters" {
      let pretty-name = if locale == "hr" {
        "Diplomski rad"
      } else if locale == "en" {
        "Master's Thesis"
      } else {
        "Diplomski rad"
      }
      return ("masters", pretty-name)
    } else {
      return ("seminar", pretty-name)
    }
  } else {
    panic("invalid document kind:", repr(name), "(" + str(type(name)) + ")")
  }
}

#let title-page(
  university,
  study,
  class,
  kind,
  title,
  author,
  attributions,
  logo,
  location,
  date: none,
  locale: "hr"
) = [
  #set text(size: 16pt)
  #set align(center)

  #let used-logo = if logo == none or kind.at(0) == "seminar" {
    text(
      university,
      font: ("Arial", "Liberation Sans"),
      weight: "bold",
      size: 1.5em
    )
  } else if type(logo) == str {
    image(logo, height: 15.15mm)
  } else {
    logo
  }

  #let (author-count, author-gender, author-list) = if locale == "hr" {
    get-name-count-gender(author, locale: locale)
  } else {
    if type(author) == str {
      if author.contains(" AND ") {
        (1, 0, author.split(" AND "))
      } else {
        (0, 0, (author,))
      }
    } else if type(author) == array {
      if author.len() > 1 {
        (1, 0, author)
      } else {
        (0, 0, author)
      }
    } else {
      (0, 0, (author,))
    }
  }
  #let authors-display = if author-list.len() < 2 {
    author-list.at(0)
  } else {
    author-list.join(", ")
  }

  #let center-content = if kind.at(0) == "seminar" {
    let used-kind = if class == none {
      kind.at(1)
    } else {
      let (for-class, for-class-suffix) = if locale == "hr" {
        ("iz kolegija", none)
      } else if locale == "en" {
        ("for", "class")
      } else {
        ("iz kolegija", none)
      }
      [#kind.at(1) #for-class#linebreak() #text(weight: "bold", smallcaps(class)) #for-class-suffix]
    }
    align(bottom, stack(
      spacing: 20pt,
      text(size: 18pt, used-kind),
      text(size: 28pt, title),
    ))
  } else {
    align(bottom, stack(
      spacing: 20pt,
      text(size: 18pt, authors-display),
      text(size: 28pt, title),
      text(size: 18pt, kind.at(1)),
    ))
  }

  #let bottom-content = if kind.at(0) == "seminar" {
    let author-word = if locale == "hr" {
      let result = word-root-transform("autor", count: author-count, gender: author-gender, language: locale)
      if result != none {
        result.at(0)
      } else {
        "autor"
      }
    } else {
      if author-count == 0 {
        "author"
      } else {
        "authors"
      }
    }
    author-word = upper(author-word.at(0)) + author-word.slice(1)
    let author = [*#author-word:* #authors-display]
    [
      #author

      #attributions
    ]
  } else {
    attributions
  }

  #let used-date = if date != none {
    date
  } else {
    datetime.today()
  }

  #grid(
    rows: (auto, 1fr, 1fr, auto),
    columns: 1fr,

    stack(
      spacing: 20pt,
      used-logo,
      study
    ),

    center-content,

    align(horizon+left, bottom-content),

    align(center)[
      #location, #locale-date-format(locale, used-date)
    ]
  )
  #pagebreak()
]

#let footer-format = context {
  let doc-start = locate(<first-page>).position()
  if here().page() < doc-start.page {
    return
  }
  align(right, text(
    weight: "regular",
    size: 12pt,
    counter(page).display()
  ))
}

#let _figure-is-formula(it) = {
  let body = it.fields().at("body")
  if repr(body.func()) == "equation" {
    true
  } else if repr(body.func()) == "sequence" {
    let is-equation = false
    for child in body.children {
      if type(child) != content {
        continue
      }
      if repr(child.func()) == "space" {
        continue
      }
      if repr(child.func()) == "equation" {
        is-equation = true
        continue
      }
      is-equation = false
      break
    }

    if is-equation {
      true
    } else {
      false
    }
  } else {
    false
  }
}

#let figure-list(locale: "hr") = context {
  if query(figure.where(kind: table)).len() > 0 {
    pagebreak()
    heading(numbering: none)[Popis tablica]
    custom-outline(figure.where(kind: table))
  }
  if query(figure.where(kind: image)).len() > 0 {
    pagebreak()
    heading(numbering: none)[Popis slika]
    custom-outline(
      figure.where(kind: image),
      filter: it => {
        not _figure-is-formula(it.at(1))
      }
    )
  }
  if query(figure.where(kind: raw)).len() > 0 {
    pagebreak()
    heading(numbering: none)[Popis priloga]
    custom-outline(
      figure.where(kind: raw),
      heading.where(supplement: [Prilog])
    )
  }
}

#let config = (
  university: "Fakultet informatike i digitalnih tehnologija",
  study: "Sveučilišni prijediplomski studij Informatika",
  kind,
  title,
  author,
  class: none,
  attributions: [],
  logo: _default-logo,
  location: "Rijeka",
  locale: "hr",
  problem-statement: none,
  summary: [],
  keywords: (),

  inserts: [],

  bibliography-columns: none,
  bibliography-file: "bibliography.bib",
  bibliography-style: "ieee",

  date: none,

  print-version: false,
) => {
  return doc => {
    set page(
      paper: "a4",
      margin: 2.5cm,
    )
    set text(lang: locale)

    let (kind, kind-display) = _map-kind-name(kind, locale: locale)

    title-page(
      university,
      study,
      class,
      (kind, kind-display),
      title,
      author,
      attributions,
      logo,
      location,
      date: date,
      locale: locale,
    )
    if print-version {
      pagebreak()
    }

    set page(
      numbering: "1",
      footer: footer-format
    )
    
    set text(
      font: ("Times New Roman", "Liberation Serif"),
      size: 12pt,
    )

    set par(
      justify: true,
      leading: 0.15em + 1em * 0.25, // line height 1.15em - 0.15em + descent
      spacing: 6pt + 1em * 0.25,
    )
    
    set heading(
      numbering: "1.1.",
      supplement: "dijelu"
    )
    show heading: set text(
      font: ("Arial", "Liberation Sans"),
    )
    show heading.where(level: 1): set text(size: 16pt)
    show heading.where(level: 1): it => {
      block(
        above: 0pt,
        below: 12pt,
        it
      )
    }
    show heading.where(level: 2): set text(size: 14pt)
    show heading.where(level: 2): it => block(
      above: 18pt,
      below: 6pt,
      it
    )
    show heading.where(level: 3): set text(size: 12pt)
    show heading.where(level: 3): it => block(
      above: 6pt,
      below: 6pt,
      it
    )
    show heading.where(level: 4): set text(size: 12pt)
    show heading.where(level: 4): it => block(
      above: 6pt,
      below: 6pt,
      it
    )

    set list(
      marker: "-",
      indent: 6.35mm,
      body-indent: 6.35mm - 0.6em,
      spacing: 0.7em
    )
    set enum(
      indent: 6.35mm,
      body-indent: 6.35mm - 0.6em,
      spacing: 0.7em
    )

    show figure.caption: set text(
      font: ("Times New Roman", "Liberation Serif"),
      size: 10pt,
    )
    show figure.where(kind: table): set figure(supplement: if locale == "hr" {
      "Tablica"
    } else {
      "Table"
    })
    show figure.where(kind: table): it => [
      #set figure.caption(position: top)
      #it
    ]
    show figure.where(kind: raw): set figure(supplement: if locale == "hr" {
      "Kȏd"
    } else {
      "Code"
    })
    show figure.where(kind: raw): it => [
      #show raw: set text(
        font: ("Consolas", "Courier New", "Liberation Mono"),
        size: 9pt,
      )
      #set par(
        leading: 0.5em,
      )
      #set block(width: 100%)
      #it
    ]
    show figure.where(kind: image): set figure(supplement: if locale == "hr" {
      "Slika"
    } else {
      "Figure"
    })

    show figure.where(kind: image): it => {
      if _figure-is-formula(it) {
        let location = here()
        figure(
          it.fields().at("body"),
          kind: "formula",
          supplement: none,
          caption: context {
            let index = counter(figure.where(kind: "formula")).get().at(0)
            [(#index)#metadata((
              formula: index,
              caption: it.fields().at("caption", default: (body: none)).at("body", default: none),
              location: location,
            ))]
          },
        )
        // revert image counter
        counter(figure.where(kind: image)).update(it => it - 1)
      } else {
        it
      }
    }

    // Uključuje ascent i descent u veličinu znaka za računanje razmaka
    // Ascent i descent ovise o fontu, ali obično su 50% ukupne visine glifa
    show heading: set block(inset: (y: 0.25em))

    show ref: it => {
      let el = it.element
      if el == none {
        return it
      }
      let func = el.func()
      if func == figure and _figure-is-formula(el) {
        let data = query(
          selector(metadata).after(el.location())
        ).first()
        if data == none {
          panic("formula missing metadata", el)
        } else {
          data = data.at("value")
        }
        let index = data.at("formula", default: none)
        let caption = data.at("caption", default: none)
        let location = data.at("location", default: none)
        if caption == none {
          link(location)[(#index)]
        } else {
          link(location)[#caption (#index)]
        }
        return
      }

      if func == heading {
        let supplement = it.supplement
        if supplement == auto {
          supplement = el.supplement
        }
        link(el.location())[#numbering(el.numbering, ..counter(heading).at(el.location())) #supplement]
        return
      }
      
      it
    }

    // Popravlja outline za formule jer njihov caption ovisi o kontekstu pa se
    // krivo pokazuje u outlineu. Također, stvarni caption nije uključen.
    show outline.where(target: figure.where(kind: "formula")): it => {
      show outline.entry: entry => {
        let location = entry.element.location()
        let index = counter(figure.where(kind: "formula")).at(location).at(0)
        let caption = query(metadata).find(it => {
          let value = it.at("value", default: none)
          if type(value) != dictionary {
            return false
          }
          return value.at("formula", default: none) == index
        })
        if caption != none {
          caption = caption.at("value").at("caption", default: none)
        }
        if caption == none {
          link(location)[(#index) #box(width: 1fr, repeat[.]) #entry.page]
        } else {
          link(location)[(#index) #caption #box(width: 1fr, repeat[.]) #entry.page]
        }
      }
      it
    }

    if problem-statement != none {
      problem-statement
    } else if kind != "seminar" {
      text(
        weight: "bold",
        if locale == "hr" {
          "(Iza naslovne stranice, na ovome mjestu, prilikom uvezivanja umetnite original zadatka završnog rada kojeg ste preuzeli od mentora)"
        } else {
          "(When binding the document, insert the original problem statement you got from your mentor in place of this page)"
        }
      )
      pagebreak()
      if print-version {
        pagebreak()
      }
    }

    if kind != "seminar" {
      text(size: 14pt, weight: "bold")[Sažetak]
      v(5pt)

      // Treba biti 100-300 riječi:

      word-count(total => [
        #summary

        #{
          if print-version {
            return
          }
          if total.words < _min_summary_words {
            place(bottom+center, rect(
              fill: red,
              outset: 2em,
              text(
                fill: white,
                weight: "black",
                size: 2em,
                if locale == "hr" {
                  "Sažetak je pre kratak (" + str(total.words) + " riječi)"
                } else {
                  "Summary too short (" + str(total.words) + " words)"
                }
              )
            ))
          } else if total.words > _max_summary_words {
            place(bottom+center, rect(fill: red, text(
              fill: white,
              weight: "black",
              size: 2em,
              if locale == "hr" {
                "Sažetak je pre dug (" + str(total.words) + " riječi)"
              } else {
                "Summary too long (" + str(total.words) + " words)"
              }
            )))
          }
        } <no-wc>
      ])

      v(10pt)
      text(weight: "bold", if locale == "hr" {
        "Ključne riječi"
      } else {
        "Keywords"
      } + ": ")
      text(keywords.join("; "))

      pagebreak()
      if print-version {
        pagebreak()
      }
    }

    inserts

    context {
      let contents-start = counter(page).get().at(0)
      outline(
        title: "SADRŽAJ",
        indent: auto
      )
      let contents-end = counter(page).get().at(0)

      pagebreak()
      if calc.rem-euclid(contents-end - contents-start, 2) != 0 and print-version {
        pagebreak()
      }
    }

    counter(page).update(1)

    [#metadata((tag: "location-marker")) <first-page>]

    doc

    if bibliography-file != none {
      let bibliography-title = if locale == "hr" {
        "Literatura"
      } else {
        "Bibliography"
      }
      if bibliography-columns == none {
        bibliography(
          title: bibliography-title,
          "../" + bibliography-file,
          style: bibliography-style
        )
      } else {
        columns(bibliography-columns, bibliography(
          title: bibliography-title,
          "../" + bibliography-file,
          style: bibliography-style
        ))
      }
    }

    if kind != "seminar" {
      figure-list()
    }
  }
}

#let horizontal-page(body) = {
  set page(
    flipped: true,
    header: context {
      let doc-start = locate(<first-page>).position()
      if here().page() < doc-start.page {
        return
      }
      align(right, move(dy: 2em, dx: 2em, rotate(-90deg, text(
        weight: "regular",
        size: 12pt,
        counter(page).display()
      ))))
    },
    footer: [],
  )
  body
}

#let appendix(body) = context {
  let heading_before = counter(heading).get()
  counter(heading).update(it => 0)
  set heading(numbering: "A", supplement: [Prilog])
  body
  counter(heading).update(it => heading_before)
}
