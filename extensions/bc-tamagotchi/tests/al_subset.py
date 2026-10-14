"""Restricted evaluator for our own AL minute/care tests; no BC runtime.

No ROM, emulator or external source is read. Helper adapters are explicit.
"""
import re

PRECEDENCE = {'or': 1, 'and': 2, '=': 3, '<>': 3, '<': 3, '>': 3,
              '<=': 3, '>=': 3, '+': 4, '-': 4, '*': 5, 'div': 5, 'mod': 5}


class ALParser:
    def __init__(self, value):
        self.tokens = re.findall(r'\d+|[A-Za-z_]\w*|:=|<>|<=|>=|[();,+\-*=<>]', value)
        if ''.join(self.tokens) != re.sub(r'\s+', '', value):
            raise ValueError('Unsupported syntax in our generated AL')
        self.index = 0

    def peek(self):
        return self.tokens[self.index].lower() if self.index < len(self.tokens) else ''

    def pop(self, expected=None):
        value = self.peek()
        if not value or (expected and expected != value): raise ValueError((expected, value, self.index))
        self.index += 1
        return value

    def expression(self, minimum=0):
        value = self.pop()
        if value in ('not', '-'):
            left = ('unary', value, self.expression(6))
        elif value == '(':
            left = self.expression(); self.pop(')')
        elif value.isdecimal(): left = ('number', int(value))
        else:
            left = ('name', value)
            if self.peek() == '(':
                self.pop('('); arguments = []
                if self.peek() != ')':
                    arguments.append(self.expression())
                    while self.peek() == ',': self.pop(','); arguments.append(self.expression())
                self.pop(')'); left = ('call', value, arguments)
        while self.peek() in PRECEDENCE and PRECEDENCE[self.peek()] >= minimum:
            operator = self.pop()
            left = ('binary', operator, left, self.expression(PRECEDENCE[operator]+1))
        return left

    def block(self):
        self.pop('begin'); statements = []
        while self.peek() != 'end': statements.append(self.statement())
        self.pop('end')
        return statements

    def statement(self):
        if self.peek() == 'if':
            self.pop('if'); condition = self.expression(); self.pop('then')
            yes = self.block(); no = []
            if self.peek() == 'else': self.pop('else'); no = self.block()
            self.pop(';'); return ('if', condition, yes, no)
        expr = self.expression()
        if self.peek() == ':=':
            self.pop(':='); rhs = self.expression(); self.pop(';'); return ('assign', expr[1], rhs)
        self.pop(';'); return ('call', expr)


class SyntheticAL:
    def expression(self, node):
        kind = node[0]
        if kind == 'number': return node[1]
        if kind == 'name':
            if node[1] in ('true', 'false'): return node[1] == 'true'
            return self.values[node[1]]
        if kind == 'unary':
            value = self.expression(node[2]); return not value if node[1] == 'not' else -value
        if kind == 'call': return self.call(node[1], [self.expression(n) for n in node[2]])
        if kind == 'binary':
            op = node[1]; a, b = self.expression(node[2]), self.expression(node[3])
            if op == '+': return a+b
            if op == '-': return a-b
            if op == '*': return a*b
            if op == 'div': return int(a/b)
            if op == 'mod': return a - int(a/b)*b
            if op == '=': return a == b
            if op == '<>': return a != b
            if op == '<': return a < b
            if op == '>': return a > b
            if op == '<=': return a <= b
            if op == '>=': return a >= b
            if op == 'and': return a and b
            if op == 'or': return a or b
        raise ValueError(node)

    def run_statements(self, statements):
        for node in statements:
            if node[0] == 'if': self.run_statements(node[2] if self.expression(node[1]) else node[3])
            elif node[0] == 'assign': self.values[node[1]] = self.expression(node[2])
            elif node[0] == 'call': self.expression(node[1])
            else: raise ValueError(node)

