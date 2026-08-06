import re


def apply(text: str, config: dict) -> str:
    """Collapse a multiline anonymous function whose body is a single `return <expr>`.

        function(c)
                return c.setFollowTarget
        end
    ->
        function(c) return c.setFollowTarget end

    Only collapses when the return expression is one line and contains no
    nested `function`/`end`, so real multi-statement bodies are untouched.
    """
    pattern = re.compile(
        r"(\bfunction\s*\([^()\n]*\))\s*\n([ \t]*)return\s+([^\n]+?)\s*\n[ \t]*end"
    )

    def repl(m):
        expr = m.group(3)
        if re.search(r"\b(function|end)\b", expr):
            return m.group(0)
        return f"{m.group(1)} return {expr} end"

    return pattern.sub(repl, text)
