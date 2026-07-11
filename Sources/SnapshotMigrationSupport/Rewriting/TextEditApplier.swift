struct TextEdit: Hashable {
  let startUTF8Offset: Int
  let endUTF8Offset: Int
  let replacement: String
}

struct TextEditApplier {
  static func apply(edits: [TextEdit], to source: String) -> String {
    var seen: Set<TextEdit> = []
    let indexedEdits = edits.enumerated().compactMap { index, edit -> IndexedEdit? in
      guard seen.insert(edit).inserted else { return nil }
      precondition(
        edit.startUTF8Offset >= 0
          && edit.endUTF8Offset >= edit.startUTF8Offset
          && edit.endUTF8Offset <= source.utf8.count,
        "Text edit range is outside the source buffer"
      )
      return IndexedEdit(edit: edit, originalIndex: index)
    }

    let rangeEdits = indexedEdits
      .filter { !$0.edit.isInsertion }
      .sorted {
        if $0.edit.startUTF8Offset == $1.edit.startUTF8Offset {
          return $0.edit.endUTF8Offset < $1.edit.endUTF8Offset
        }
        return $0.edit.startUTF8Offset < $1.edit.startUTF8Offset
      }
    for (previous, current) in zip(rangeEdits, rangeEdits.dropFirst()) {
      precondition(
        current.edit.startUTF8Offset >= previous.edit.endUTF8Offset,
        "Overlapping non-empty text edit ranges are ambiguous"
      )
    }

    let insertions = indexedEdits
      .filter { $0.edit.isInsertion }
      .sorted {
        if $0.edit.startUTF8Offset == $1.edit.startUTF8Offset {
          return $0.originalIndex < $1.originalIndex
        }
        return $0.edit.startUTF8Offset < $1.edit.startUTF8Offset
      }

    var output = ""
    var sourceCursor = 0
    var insertionCursor = 0

    for indexedRange in rangeEdits {
      let range = indexedRange.edit

      while insertionCursor < insertions.count,
            insertions[insertionCursor].edit.startUTF8Offset < range.startUTF8Offset
      {
        let insertion = insertions[insertionCursor].edit
        precondition(insertion.startUTF8Offset >= sourceCursor)
        output += sourceSlice(source, from: sourceCursor, to: insertion.startUTF8Offset)
        output += insertion.replacement
        sourceCursor = insertion.startUTF8Offset
        insertionCursor += 1
      }

      precondition(range.startUTF8Offset >= sourceCursor)
      output += sourceSlice(source, from: sourceCursor, to: range.startUTF8Offset)
      sourceCursor = range.startUTF8Offset

      while insertionCursor < insertions.count,
            insertions[insertionCursor].edit.startUTF8Offset == range.startUTF8Offset
      {
        output += insertions[insertionCursor].edit.replacement
        insertionCursor += 1
      }

      output += range.replacement
      while insertionCursor < insertions.count,
            insertions[insertionCursor].edit.startUTF8Offset < range.endUTF8Offset
      {
        output += insertions[insertionCursor].edit.replacement
        insertionCursor += 1
      }
      sourceCursor = range.endUTF8Offset
    }

    while insertionCursor < insertions.count {
      let insertion = insertions[insertionCursor].edit
      precondition(insertion.startUTF8Offset >= sourceCursor)
      output += sourceSlice(source, from: sourceCursor, to: insertion.startUTF8Offset)
      output += insertion.replacement
      sourceCursor = insertion.startUTF8Offset
      insertionCursor += 1
    }

    output += sourceSlice(source, from: sourceCursor, to: source.utf8.count)
    return output
  }

  private static func sourceSlice(_ source: String, from start: Int, to end: Int) -> String {
    let startIndex = stringIndex(in: source, utf8Offset: start)
    let endIndex = stringIndex(in: source, utf8Offset: end)
    return String(source[startIndex..<endIndex])
  }

  private static func stringIndex(in source: String, utf8Offset: Int) -> String.Index {
    let index = source.utf8.index(source.utf8.startIndex, offsetBy: utf8Offset)
    return String.Index(index, within: source) ?? source.endIndex
  }
}

private struct IndexedEdit {
  let edit: TextEdit
  let originalIndex: Int
}

private extension TextEdit {
  var isInsertion: Bool {
    startUTF8Offset == endUTF8Offset
  }
}
