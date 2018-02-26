var webpack = require('webpack'),
    path = require('path'),
    ngAnnotatePlugin = require('ng-annotate-webpack-plugin'),
    MinifyPlugin = require("babel-minify-webpack-plugin");

module.exports = {
  entry: './src-coffee/meetup.coffee',
  output: {
    path:  path.join(__dirname, 'src-js'),
    filename: 'meetup.min.js'
  },
  module: {
    loaders: [
      {
        test: /\.coffee$/,
        loader: "coffee-loader"
      }
    ]
  },
    plugins: [
      new ngAnnotatePlugin({
        add: true,
        // other ng-annotate options here
      }),
      new MinifyPlugin({})
    ]
};
