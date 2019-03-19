The demo included with AllenNLP is built using NPM so we can compile our assets
and code before it ends up on the client's machine.  This way, less data needs
to flow over the wire, less computation needs to take place on the client's
machine, and best practices can be enforced at compile time by automated
tools.

## Building and running the demo

First, make sure you have a relatively new version of `npm` installed on your
system.  If you are on a Mac, you can install `npm` with `brew install node`.

```
# npm -v
5.3.0
```

Next, you will need to install the dependencies specified in `package.json`.
You only need to run this once, or whenever dependencies are updated.  This
will install your dependencies into the newly created `node_modules` subfolder.

```
npm install
```

Now you can build the application.

```
npm run build
```

Built assets are placed in the `build` subfolder, which the Sanic server is
configured to use.

Now to run the demo, you can `cd` to the root AllenNLP directory and run the
following.

```
./bin/allennlp serve
```

You may need to force refresh your web browser.

If you are developing the Javascript, then you will want to run that portion
through npm itself.  This way the browser will refresh after each code change.

```
npm start
```

```json
{"passage":"Robotics is an interdisciplinary branch of engineering and science that includes mechanical engineering, electrical engineering, computer science, and others. Robotics deals with the design, construction, operation, and use of robots, as well as computer systems for their control, sensory feedback, and information processing. These technologies are used to develop machines that can substitute for humans. Robots can be used in any situation and for any purpose, but today many are used in dangerous environments (including bomb detection and de-activation), manufacturing processes, or where humans cannot survive. Robots can take on any form but some are made to resemble humans in appearance. This is said to help in the acceptance of a robot in certain replicative behaviors usually performed by people. Such robots attempt to replicate walking, lifting, speech, cognition, and basically anything a human can do.","question":"What do robots that resemble humans attempt to do?"}
```

