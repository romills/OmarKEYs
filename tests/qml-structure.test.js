const test = require("node:test")
const assert = require("node:assert")
const fs = require("node:fs")
const path = require("node:path")

const root = path.join(__dirname, "..")
const qmlFiles = fs.readdirSync(root).filter((f) => f.endsWith(".qml"))

// Assigning the same property twice in one object makes QML refuse to load
// the whole component -- and everything that uses it. That is how the
// overlay stopped opening once: a stray second `opacity` on one label took
// KeymapOptionsMenu down, which took Keymap.qml with it.
//
// qmllint does not report this at all, and there is no qmlcachegen here to
// compile against, so the runtime was the only thing that caught it. This
// is cheaper than restarting a shell to find out.
function duplicateProps(source) {
  const lines = source.split("\n")
  const found = []
  const seen = [new Map()]
  let depth = 0
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].split("//")[0]
    const opens = (line.match(/\{/g) || []).length
    const closes = (line.match(/\}/g) || []).length
    // A binding on its own line: `name: value`, not `name: Thing {`.
    const m = line.match(/^\s*([a-z][A-Za-z0-9_.]*)\s*:/)
    if (m && opens === 0) {
      const prop = m.group === undefined ? m[1] : m[1]
      const at = seen[depth] || (seen[depth] = new Map())
      if (at.has(prop))
        found.push(`line ${i + 1}: '${prop}' already set at line ${at.get(prop)}`)
      else
        at.set(prop, i + 1)
    }
    for (let o = 0; o < opens; o++) {
      depth++
      seen[depth] = new Map()
    }
    for (let c = 0; c < closes; c++) {
      seen[depth] = new Map()
      depth = Math.max(0, depth - 1)
    }
  }
  return found
}

test("no QML object sets the same property twice", () => {
  for (const file of qmlFiles) {
    const dupes = duplicateProps(fs.readFileSync(path.join(root, file), "utf8"))
    assert.deepEqual(dupes, [], `${file}\n  ${dupes.join("\n  ")}`)
  }
})

test("the duplicate check would have caught the one that broke the overlay", () => {
  const broken = [
    "Text {",
    "  id: holdLabel",
    "  opacity: host.holdEnabled ? 0.75 : 0.4",
    '  text: "Hold Super"',
    "  opacity: 0.75",
    "}"
  ].join("\n")
  const dupes = duplicateProps(broken)
  assert.equal(dupes.length, 1)
  assert.match(dupes[0], /'opacity' already set at line 3/)
})

// Splicing a block into a QML file by hand is easy to get wrong by one
// brace, and qmllint did not object when it happened -- the file simply
// stopped meaning what it looked like it meant.
function braceDepth(source) {
  let depth = 0
  let min = 0
  for (const raw of source.split("\n")) {
    const code = raw.split("//")[0].replace(/"(?:[^"\\]|\\.)*"/g, '""')
    for (const ch of code) {
      if (ch === "{") depth++
      else if (ch === "}") { depth--; if (depth < min) min = depth }
    }
  }
  return { depth, min }
}

test("every QML file closes every brace it opens", () => {
  for (const file of qmlFiles) {
    const { depth, min } = braceDepth(fs.readFileSync(path.join(root, file), "utf8"))
    assert.equal(depth, 0, `${file} ends at brace depth ${depth}`)
    assert.equal(min, 0, `${file} closes a brace it never opened`)
  }
})

// The version list, the channel tabs and the track row moved out of
// OmarKEYS into OmarVerTester -- picking and installing versions of a
// plugin is that tool's job, not a keymap overlay's. The test that pinned
// the cross-track version list went with them: there is no list here to
// filter any more.
