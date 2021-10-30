@{%
	console.clear();
	const moo = require('moo');
	const lexer = moo.compile({
		number: /(?:\+|-)?[0-9]+(?:\.[0-9]+)?/,
		'true': 'true',
		'false': 'false',
		'null': 'null',
		space: {
			match: /\s+/, lineBreaks: true
		},
		string: [
			{
				match: /"(?:\\["nrt]|[^"\\])*"/, value: x => x.slice(1, -1)
			},
			{
				match: /'(?:\\['nrt]|[^'\\])*'/, value: x => x.slice(1, -1)
			},
			{
				match: /`(?:\\[`nrt]|[^`\\])*`/, value: x => JSON.stringify(x).slice(2, -2), lineBreaks: true
			},
		],
		hex: /#(?:[A-Za-z0-9]{3}|[A-Za-z0-9]{6})\b/,
		comment: /\/\/.*/,
		plus: '+',
		'[': '[',
		']': ']',
		'(': '(',
		')': ')',
		',': ',',
		identifier: /[A-Za-z_]+[A-Za-z_0-9]*/,
	})
%}

@lexer lexer

process -> main _ {% id %}

main -> (_ value):* {% v => v[0].map(i => i[1]) %}

value -> number {% id %}
	| boolean {% id %}
	| myNull {% id %}
	| string {% id %}
	| hex {% id %}
	| array {% id %}

array -> "[" _ "]" {% v => [] %}
	| "[" _ value (_ "," _ value):* (_ ","):? _ "]" {% v => {
	let output = [v[2]];
	for (let i in v[3]) {
		output.push(v[3][i][3]);
	}
	return output;
} %}
	| function {% (v, l, reject) => {
	if (Array.isArray(v[0]))
		return v[0];
	return reject;
} %}

function -> %identifier _ arguments {% v => {
	if (functions[v[0].value])
		return functions[v[0].value](...v[2])
	else console.error('Function does not exist')
} %}

arguments -> "(" _ ")" {% v => [] %}
	| value {% v => [v[0]] %}
	| "(" _ value (_ "," _ value):* (_ ","):? _ ")" {% v => {
	let output = [v[2]];
	for (let i in v[3]) {
		output.push(v[3][i][3]);
	}
	return output;
} %}

number -> %number {% v => +v[0].value %}
	| function {% (v, l, reject) => {
	if (typeof v[0] === 'number')
		return v[0];
	return reject;
} %}

string -> %string {% v => v[0].value %}
	| string_concat {% id %}
	| function {% (v, l, reject) => {
	if (typeof v[0] === 'string')
		return v[0];
	return reject;
} %}
	
string_concat -> %string _ "+" _ %string {% v => v[0].value + v[4].value %}
	| string_concat _ "+" _ %string {% v => v[0] + v[4].value %}

hex -> %hex {% v => v[0].value %}

boolean -> "true" {% v => true %}
	| "false" {% v => false %}
	
myNull -> "null" {% v => null %}

_ -> (%space %comment):* %space {% v => '' %}
	| null {% v => '' %}

__ -> %space {% v => ' ' %}

@{%
	const functions = {
		floor: Math.floor,
		round: Math.round,
		ceil: Math.ceil,
		sqrt: Math.sqrt,
		pow: Math.pow,
		length (item) {
			if (typeof item === 'string')
				return item.length;
			if (Array.isArray(item))
				return item.length;
			throw 'Not a string or array';
		},
		join (array, separator) {
			if (!Array.isArray(array)) throw 'Array is required';
			if (array.length === 0) return '';
			array.map(i => '' + i);
			return array.join(
				separator !== undefined ? '' + separator : ''
			)
		}
	}
%}
