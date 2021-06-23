(function (root, factory) {
  if (typeof define === 'function' && define.amd) {
    // AMD. Register as an anonymous module.
    define(['exports', 'echarts'], factory);
  } else if (typeof exports === 'object' && typeof exports.nodeName !== 'string') {
    // CommonJS
    factory(exports, require('echarts'));
  } else {
    // Browser globals
    factory({}, root.echarts);
  }
}(this, function (exports, echarts) {
  var log = function (msg) {
    if (typeof console !== 'undefined') {
      console && console.error && console.error(msg);
    }
  };
  if (!echarts) {
    log('ECharts is not Loaded');
    return;
  }
  echarts.registerTheme('tingyun', {
    'color': [
      '#5b8ff9',
      '#5ad8a6',
      '#5d7092',
      '#f6bd16',
      '#e86452',
      '#6dc8ec',
      '#945fb9',
      '#ff9845',
      '#1e9493',
      '#ff99c3',
    ],
    'backgroundColor': 'rgba(0, 0, 0, 0)',
    'textStyle': {},
    'title': {
      'textStyle': {
        'color': 'rgba(0,0,0,0.85)',
      },
      'subtextStyle': {
        'color': 'rgba(0,0,0,0.65)',
      },
    },
    'line': {
      'itemStyle': {
        'borderWidth': 1,
      },
      'lineStyle': {
        'width': 2,
      },
      'symbolSize': '6',
      'symbol': 'circle',
      'smooth': false,
    },
    'radar': {
      'itemStyle': {
        'borderWidth': 1,
      },
      'lineStyle': {
        'width': 2,
      },
      'symbolSize': '6',
      'symbol': 'circle',
      'smooth': false,
    },
    'bar': {
      'itemStyle': {
        'barBorderWidth': '0',
        'barBorderColor': 'rgba(65,97,128,0.45)',
      },
    },
    'pie': {
      'itemStyle': {
        'borderWidth': '0',
        'borderColor': 'rgba(65,97,128,0.45)',
      },
    },
    'scatter': {
      'itemStyle': {
        'borderWidth': '0',
        'borderColor': 'rgba(65,97,128,0.45)',
      },
    },
    'boxplot': {
      'itemStyle': {
        'borderWidth': '0',
        'borderColor': 'rgba(65,97,128,0.45)',
      },
    },
    'parallel': {
      'itemStyle': {
        'borderWidth': '0',
        'borderColor': 'rgba(65,97,128,0.45)',
      },
    },
    'sankey': {
      'itemStyle': {
        'borderWidth': '0',
        'borderColor': 'rgba(65,97,128,0.45)',
      },
    },
    'funnel': {
      'itemStyle': {
        'borderWidth': '0',
        'borderColor': 'rgba(65,97,128,0.45)',
      },
    },
    'gauge': {
      'itemStyle': {
        'borderWidth': '0',
        'borderColor': 'rgba(65,97,128,0.45)',
      },
    },
    'candlestick': {
      'itemStyle': {
        'color': '#eb5454',
        'color0': '#47b262',
        'borderColor': '#eb5454',
        'borderColor0': '#47b262',
        'borderWidth': 1,
      },
    },
    'graph': {
      'itemStyle': {
        'borderWidth': '0',
        'borderColor': 'rgba(65,97,128,0.45)',
      },
      'lineStyle': {
        'width': 1,
        'color': '#aaa',
      },
      'symbolSize': '6',
      'symbol': 'circle',
      'smooth': false,
      'color': [
        '#5b8ff9',
        '#5ad8a6',
        '#5d7092',
        '#f6bd16',
        '#e86452',
        '#6dc8ec',
        '#945fb9',
        '#ff9845',
        '#1e9493',
        '#ff99c3',
      ],
      'label': {
        'color': 'rgba(44,53,66,0.45)',
      },
    },
    'map': {
      'itemStyle': {
        'normal': {
          'areaColor': '#eee',
          'borderColor': '#444',
          'borderWidth': 0.5,
        },
        'emphasis': {
          'areaColor': 'rgba(255,215,0,0.8)',
          'borderColor': '#444',
          'borderWidth': 1,
        },
      },
      'label': {
        'normal': {
          'textStyle': {
            'color': '#000',
          },
        },
        'emphasis': {
          'textStyle': {
            'color': 'rgb(100,0,0)',
          },
        },
      },
    },
    'geo': {
      'itemStyle': {
        'normal': {
          'areaColor': '#eee',
          'borderColor': '#444',
          'borderWidth': 0.5,
        },
        'emphasis': {
          'areaColor': 'rgba(255,215,0,0.8)',
          'borderColor': '#444',
          'borderWidth': 1,
        },
      },
      'label': {
        'normal': {
          'textStyle': {
            'color': '#000',
          },
        },
        'emphasis': {
          'textStyle': {
            'color': 'rgb(100,0,0)',
          },
        },
      },
    },
    'categoryAxis': {
      'axisLine': {
        'show': true,
        'lineStyle': {
          'color': 'rgba(65,97,128,0.45)',
        },
      },
      'axisTick': {
        'show': true,
        'lineStyle': {
          'color': 'rgba(65,97,128,0.35)',
        },
      },
      'axisLabel': {
        'show': true,
        'textStyle': {
          'color': 'rgba(44,53,66,0.45)',
        },
      },
      'splitLine': {
        'show': true,
        'lineStyle': {
          'color': [
            'rgba(65,97,128,0.15)',
          ],
        },
      },
      'splitArea': {
        'show': false,
        'areaStyle': {
          'color': [
            'rgba(250,250,250,0.2)',
            'rgba(210,219,238,0.2)',
          ],
        },
      },
    },
    'valueAxis': {
      'axisLine': {
        'show': true,
        'lineStyle': {
          'color': 'rgba(65,97,128,0.45)',
        },
      },
      'axisTick': {
        'show': true,
        'lineStyle': {
          'color': 'rgba(65,97,128,0.35)',
        },
      },
      'axisLabel': {
        'show': true,
        'textStyle': {
          'color': 'rgba(44,53,66,0.45)',
        },
      },
      'splitLine': {
        'show': true,
        'lineStyle': {
          'color': [
            'rgba(65,97,128,0.15)',
          ],
        },
      },
      'splitArea': {
        'show': false,
        'areaStyle': {
          'color': [
            'rgba(250,250,250,0.2)',
            'rgba(210,219,238,0.2)',
          ],
        },
      },
    },
    'logAxis': {
      'axisLine': {
        'show': true,
        'lineStyle': {
          'color': 'rgba(65,97,128,0.45)',
        },
      },
      'axisTick': {
        'show': true,
        'lineStyle': {
          'color': 'rgba(65,97,128,0.35)',
        },
      },
      'axisLabel': {
        'show': true,
        'textStyle': {
          'color': 'rgba(44,53,66,0.45)',
        },
      },
      'splitLine': {
        'show': true,
        'lineStyle': {
          'color': [
            'rgba(65,97,128,0.15)',
          ],
        },
      },
      'splitArea': {
        'show': false,
        'areaStyle': {
          'color': [
            'rgba(250,250,250,0.2)',
            'rgba(210,219,238,0.2)',
          ],
        },
      },
    },
    'timeAxis': {
      'axisLine': {
        'show': true,
        'lineStyle': {
          'color': 'rgba(65,97,128,0.45)',
        },
      },
      'axisTick': {
        'show': true,
        'lineStyle': {
          'color': 'rgba(65,97,128,0.35)',
        },
      },
      'axisLabel': {
        'show': true,
        'textStyle': {
          'color': 'rgba(44,53,66,0.45)',
        },
      },
      'splitLine': {
        'show': true,
        'lineStyle': {
          'color': [
            'rgba(65,97,128,0.15)',
          ],
        },
      },
      'splitArea': {
        'show': false,
        'areaStyle': {
          'color': [
            'rgba(250,250,250,0.2)',
            'rgba(210,219,238,0.2)',
          ],
        },
      },
    },
    'toolbox': {
      'iconStyle': {
        'normal': {
          'borderColor': '#999',
        },
        'emphasis': {
          'borderColor': '#666',
        },
      },
    },
    'legend': {
      'textStyle': {
        'color': 'rgba(44,53,66,0.65)',
      },
    },
    'tooltip': {
      'axisPointer': {
        'lineStyle': {
          'color': '#ccc',
          'width': 1,
        },
        'crossStyle': {
          'color': '#ccc',
          'width': 1,
        },
      },
    },
    'timeline': {
      'lineStyle': {
        'color': '#DAE1F5',
        'width': 2,
      },
      'itemStyle': {
        'normal': {
          'color': '#A4B1D7',
          'borderWidth': 1,
        },
        'emphasis': {
          'color': '#FFF',
        },
      },
      'controlStyle': {
        'normal': {
          'color': '#A4B1D7',
          'borderColor': '#A4B1D7',
          'borderWidth': 1,
        },
        'emphasis': {
          'color': '#A4B1D7',
          'borderColor': '#A4B1D7',
          'borderWidth': 1,
        },
      },
      'checkpointStyle': {
        'color': '#316bf3',
        'borderColor': 'fff',
      },
      'label': {
        'normal': {
          'textStyle': {
            'color': '#A4B1D7',
          },
        },
        'emphasis': {
          'textStyle': {
            'color': '#A4B1D7',
          },
        },
      },
    },
    'visualMap': {
      'color': [
        '#bf444c',
        '#d88273',
        '#f6efa6',
      ],
    },
    'dataZoom': {
      'handleSize': 'undefined%',
      'textStyle': {},
    },
    'markPoint': {
      'label': {
        'color': 'rgba(44,53,66,0.45)',
      },
      'emphasis': {
        'label': {
          'color': 'rgba(44,53,66,0.45)',
        },
      },
    },
  });
}));
