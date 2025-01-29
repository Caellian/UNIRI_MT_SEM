// TODO: Outline is not customizable enough so this is a reimplementation
// See: typst#5704

#let default-outline-format = (..data) => {
  let supplement = data.at("supplement", default: none)
  if supplement != none {
    supplement = [#supplement#" "]
  }
  let body = data.at("body", default: none)
  if body != none and supplement != none {
    body = [:#" "#body]
  }

  link(
    data.at("location"),
    (
      supplement,
      data.at("numbering", default: none),
      body,
      " ", box(width: 1fr, repeat[.]), " ",
      str(data.at("page", default: none)),
    ).filter(it => it != none).join("")
  )
}

#let custom-outline(
  spacing: 6pt,
  format: default-outline-format,
  filter: it => true,
  ..targets
) = context {
  let entries = ()

  let enumerate-target = (target) => {
    let counter = counter(target)
    return query(target).map(it => (
      counter.at(it.location()).at(0), it
    ))
  }
  for target in targets.pos() {
    entries = (..entries, ..enumerate-target(target))
  }

  let footnote-counter = counter(footnote)
  let footnote-lookup = query(footnote).map(it => it.location())
  // Nested entry items aren't querried so they don't have a location (yet?), so
  // sanitize-entry-body has to be impure
  let child-mutations = state("outline-entry-caption-sanitizaion-mutations", (:))

  let sanitize-entry-body(
    body,
    location
  ) = {
    // directly forwarded component functions
    let forward = (text, ref)
    if type(body) == str {
      return body
    }
    if type(body) != content {
      panic("unsupported entry body type: " + str(type(body)))
    }
    if forward.contains(body.func()) {
      return body
    }
    if repr(body.func()) == "space" {
      return " "
    }
    if repr(body.func()) == "linebreak" {
      return " "
    }
    if repr(body.func()) == "context" {
      return body
    }
    if repr(body.func()) == "sequence" {
      let children = body.at("children", default: none)
      let result = children.map(it => {
        let result = sanitize-entry-body(it, location)
        for (k, v) in child-mutations.get().pairs() {
          let new-v = location.at(1).at(k, default: 0) + v
          location.at(1).set(k, new-v)
        }
        result
      }).join("")
      child-mutations.update(it => (:))
      return result
    }
    if body.func() == footnote {
      let footnote-location = body.location()
      let offset = 0
      footnote-location = location.at(0)
      offset = location.at(1).at("footnote", default: 0)
      child-mutations.update(it => {
        it.insert("footnote", it.at("footnote", default: 0) + 1)
      })
      let index = footnote-counter.at(footnote-location).at(0) + offset
      let footnote-location = footnote-lookup.at(index)
      return link(
        footnote-location,
        super(str(index + 1))
      )
    }
    panic("unsupported entry body content type: " + repr(body.func()))
  }
  
  let page-counter = counter(page)
  let get-entry-data((i, entry)) = {
    let location = entry.location()
    let page = page-counter.at(location).at(0)
    let (supplement, numbering, body) = if entry.fields().at("caption", default: none) != none {
      (
        entry.caption.supplement,
        numbering(
          entry.caption.numbering, i
        ),
        sanitize-entry-body(entry.caption.body, (entry.location(), (:))),
      )
    } else {
      (
        entry.supplement,
        numbering(
          entry.numbering, i
        ),
        sanitize-entry-body(entry.body, (entry.location(), (:))),
      )
    }

    return (
      location: location,
      supplement: supplement,
      numbering: numbering,
      body: body,
      page: page,
    )
  }
  
  stack(dir: ttb, spacing: spacing, ..entries.filter(filter).map(it => format(..get-entry-data(it))))
}
