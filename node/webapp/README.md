### Express web app example using node, npm and yarn

Dependencies:
- nodejs is installed
- npm is installed
- yarn is installed
- jq is in stalled
- vscode is installed


Create your app directory change into the new directory and run yarn init.
```
mkdir webapp
cd webapp
yarn init
```

Add the express package
```
yarn add express
```

Assuming you used the default index.js as your app entrypoint we need to create that file now and add it to the package.json file to the scripts section
```
touch index.js
echo 'console.log("Hello World");'>index.js

# Use jq to insert the start node of the scripts block in package.json to inddex.js
jq ".scripts.start |= \"node index.js\"" package.json | jq > package.json.tmp && mv package.json.tmp package.json

```


Check to ensure the BFF registries have been added
```
yarn config get '@bus:registry'
yarn config get '@busdk:registry'