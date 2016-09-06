function capitalizeFirstLetter(string) {
    return string.charAt(0).toUpperCase() + string.slice(1);
}

adjective = ADJECTIVES[ Math.floor(Math.random() * ADJECTIVES.length) ];
noun = NOUNS[ Math.floor(Math.random() * NOUNS.length) ];

print( capitalizeFirstLetter(adjective) + " " + capitalizeFirstLetter(noun) + " Dragon" );
