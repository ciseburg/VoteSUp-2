var expect    = require("chai").expect;
var rp        = require('request-promise');
var targetUrl   = process.env.hasOwnProperty('TARGET_URL') ? process.env.TARGET_URL : 'http://localhost:8080';

var numberOfSUTimesExpected = 4;
var expectedSUTimeProperties = ['value', 'color', 'highlight', 'label'];

describe("/data", function() {
  this.timeout(15000);

  var apiBaseurl;
  before(function(done) {
      rp({ uri: targetUrl+'/config.json', json:true})
          .then(function (data) {
              if(!data.apiBaseurl || data.apiBaseurl == '/') {
                  apiBaseurl = targetUrl;
              } else {
                  apiBaseurl = data.apiBaseurl;
              }
              done();
          })
          .catch(function (err) {
              throw err;
          });
  });

  var chartData;
  beforeEach(function(done) {
    rp({ uri: apiBaseurl+'/data', json:true})
        .then(function(data) {
          chartData = data;
            done();
        })
        .catch (function(err) {
          throw err;
        });
  });

  it("response has exactly " + numberOfSUTimesExpected + " items", function() {
    expect(chartData).to.have.length(numberOfSUTimesExpected);
  });

  it("each item has exactly " + expectedSUTimeProperties.length + " properties", function() {
    var index;
    for (index = 0; index < chartData.length; index++) {
      expect(Object.keys(chartData[index])).to.have.length(expectedSUTimeProperties.length);
    }
  });

  it("each item has properties: " + expectedSUTimeProperties, function() {
    var itemProperties;
    var itemIndex;
    var propIndex;
    for (itemIndex = 0; itemIndex < chartData.length; itemIndex++) {
      itemProperties = Object.keys(chartData[itemIndex]);
      for (propIndex = 0; propIndex < expectedSUTimeProperties.length; propIndex++) {
        expect(itemProperties).to.contain(expectedSUTimeProperties[propIndex]);
      }
    }
  });
});

describe("/data?countsOnly", function() {
  this.timeout(15000);

  var apiBaseurl;
  before(function(done) {
      rp({ uri: targetUrl+'/config.json', json:true})
          .then(function (data) {
              if(!data.apiBaseurl || data.apiBaseurl == '/') {
                  apiBaseurl = targetUrl;
              } else {
                  apiBaseurl = data.apiBaseurl;
              }
              done();
          })
          .catch(function (err) {
              throw err;
          });
  });

  var chartData;
  var colorCounts;
  beforeEach(function(done) {
    var replyCount = 0;
    rp({ uri: apiBaseurl+'/data', json:true})
        .then(function(data) {
          chartData = data;
          if(++replyCount == 2) {
              done();
          }
        })
        .catch (function(err) {
          throw err;
        });

    rp({ uri: apiBaseurl+'/data', qs:{countsOnly: true}, json:true})
        .then(function(data) {
          colorCounts = data;
          if(++replyCount == 2) {
              done();
          }
        })
        .catch (function(err) {
          throw err;
        });
  });

  it("response has exactly " + numberOfSUTimesExpected + " keys", function() {
    expect(Object.keys(colorCounts)).to.have.length(numberOfSUTimesExpected);
  });
  it("matches values in /data response", function() {
    var index;
    var color;
    var value;
    for (index = 0; index < chartData.length; index++) {
      color = chartData[index].label.toLowerCase();
      value = chartData[index].value;
      expect(colorCounts[color]).to.equal(value);
    }
  });
});
