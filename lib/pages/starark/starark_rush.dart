import 'package:ok_rush/pages/base/base_rush.dart';

const kBaseUrl = "https://h5.stararknft.art";

enum StarArkCategory { box, product, goods }

Map<StarArkCategory, Map<CategoryProperty, dynamic>> categoryMap = {
  StarArkCategory.box: {
    CategoryProperty.name: "盲盒",
    CategoryProperty.rushState: rushStateBox
  },
  StarArkCategory.product: {
    CategoryProperty.name: "产品",
    CategoryProperty.rushState: rushStateProduct
  },
  StarArkCategory.goods: {
    CategoryProperty.name: "商品",
    CategoryProperty.rushState: rushStateGoods
  }
};

enum RushState {
  none,
  fetchCaptcha,
  inputCaptcha,
  fetchTarget,
  prepareOrder,
  payOrder,
  done,
  cancel
}

const kStararkCaptchaJs = """
try {
    var captchaIns;
    initNECaptcha({
        element: "body",
        captchaId: "e21653ecb8134b5f98d1a132a63f43ea",
        width: "320px",
        mode: "popup",
        onVerify: function(e, data) {
            if (e) {
              console.log(e.message);
              Jio.postMessage(JSON.stringify({
                code: 0, message: e.message
              }));
              return;
            }
            console.log(data);
            Jio.postMessage(JSON.stringify({
              code: 1,
              message: "Success",
              data: data
            }));
        }
    }, function (instance) {
        captchaIns = instance;
    }, function (e) {
        console.log(e.message);
        Jio.postMessage(JSON.stringify({
          code: 0, message: e.message
        }));
    });
} catch(e) {
  console.log(e);
  Jio.postMessage(e.message);
}
""";

Map<RushState, dynamic> rushStateBox = {
  RushState.none: {RushStateProperty.message: "尚未运行"},
  RushState.fetchCaptcha: {
    RushStateProperty.message: "正在获取验证码",
    RushStateProperty.js: kStararkCaptchaJs
  },
  RushState.inputCaptcha: {
    RushStateProperty.message: "已获取验证码",
    RushStateProperty.parser: {
      "NECaptchaValidate": ["data", "validate"]
    }
  },
  RushState.fetchTarget: {
    RushStateProperty.message: "正在获取目标详情",
    RushStateProperty.endpoint: "/api/Box/detailed",
    RushStateProperty.query: ["id", "login_token"],
    RushStateProperty.parser: {
      "token_id": ["data", "info" ,"token_id"],
      "money": ["data", "info", "price"]
    }
  },
  RushState.prepareOrder: {
    RushStateProperty.message: "正在准备购买",
    RushStateProperty.endpoint: "/api/Pay/before_buy_box",
    RushStateProperty.query: ["id", "login_token", "token_id"],
  },
  RushState.payOrder: {
    RushStateProperty.message: "正在购买",
    RushStateProperty.endpoint: "/api/Pay/direct_buy_box",
    RushStateProperty.query: [
      "id",
      "login_token",
      "token_id",
      "money",
      "password",
      "NECaptchaValidate"
    ],
  },
  RushState.done: {RushStateProperty.message: "已停止"},
  RushState.cancel: {RushStateProperty.message: "已取消"}
};

Map<RushState, dynamic> rushStateProduct = {
  RushState.none: {RushStateProperty.message: "尚未运行"},
  RushState.fetchCaptcha: {
    RushStateProperty.message: "正在获取验证码",
    RushStateProperty.js: kStararkCaptchaJs
  },
  RushState.inputCaptcha: {
    RushStateProperty.message: "已获取验证码",
    RushStateProperty.parser: {
      "NECaptchaValidate": ["data", "validate"]
    }
  },
  RushState.fetchTarget: {
    RushStateProperty.message: "正在获取目标详情",
    RushStateProperty.endpoint: "/api/Product/detailed",
    RushStateProperty.query: ["id", "login_token"],
    RushStateProperty.parser: {
      "token_id": ["data", "token_id"],
      "money": ["data", "price"]
    }
  },
  RushState.prepareOrder: {
    RushStateProperty.message: "正在准备购买",
    RushStateProperty.endpoint: "/api/Pay/before_buy",
    RushStateProperty.query: ["id", "login_token", "token_id"]
  },
  RushState.payOrder: {
    RushStateProperty.message: "正在购买",
    RushStateProperty.endpoint: "/api/Pay/direct_buy",
    RushStateProperty.query: [
      "id",
      "login_token",
      "token_id",
      "money",
      "password",
      "NECaptchaValidate"
    ],
  },
  RushState.done: {RushStateProperty.message: "已停止"},
  RushState.cancel: {RushStateProperty.message: "已取消"}
};

Map<RushState, dynamic> rushStateGoods= {
  RushState.none: {RushStateProperty.message: "尚未运行"},
  RushState.fetchCaptcha: {
    RushStateProperty.message: "正在获取验证码",
    RushStateProperty.js: kStararkCaptchaJs
  },
  RushState.inputCaptcha: {
    RushStateProperty.message: "已获取验证码",
    RushStateProperty.parser: {
      "NECaptchaValidate": ["data", "validate"]
    }
  },
  RushState.fetchTarget: {
    RushStateProperty.message: "正在获取目标详情",
    RushStateProperty.endpoint: "/api/Goods/detailed",
    RushStateProperty.query: ["id", "login_token"],
    RushStateProperty.parser: {
      "goods_id": ["data", "id"],
    }
  },
  RushState.prepareOrder: {
    RushStateProperty.message: "正在准备购买",
    RushStateProperty.endpoint: "/api/Pay/before_buy_er",
    RushStateProperty.query: ["goods_id", "login_token"]
  },
  RushState.payOrder: {
    RushStateProperty.message: "正在购买",
    RushStateProperty.endpoint: "/api/Pay/direct_buy_er",
    RushStateProperty.query: [
      "goods_id",
      "login_token",
      "password",
      "NECaptchaValidate"
    ]
  },
  RushState.done: {RushStateProperty.message: "已停止"},
  RushState.cancel: {RushStateProperty.message: "已取消"}
};

Map<StarArkCategory, Map<String, RushStateDataType>> dataTypeMaps = {
  StarArkCategory.box: {
    "id": RushStateDataType.presets,
    "login_token": RushStateDataType.presets,
    "token_id": RushStateDataType.parsed,
    "money": RushStateDataType.parsed,
    "password": RushStateDataType.presets,
    "NECaptchaValidate": RushStateDataType.input
  },
  StarArkCategory.product: {
    "id": RushStateDataType.presets,
    "login_token": RushStateDataType.presets,
    "token_id": RushStateDataType.parsed,
    "money": RushStateDataType.parsed,
    "password": RushStateDataType.presets,
    "NECaptchaValidate": RushStateDataType.input
  },
  StarArkCategory.goods: {
    "id": RushStateDataType.presets,
    "goods_id": RushStateDataType.parsed,
    "login_token": RushStateDataType.presets,
    "token_id": RushStateDataType.parsed,
    "money": RushStateDataType.parsed,
    "password": RushStateDataType.presets,
    "NECaptchaValidate": RushStateDataType.input
  },
};

Map<String, String> headers(cookie, t, sign) {
  return {
    "accept": "*/*",
    "accept-language": "zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6",
    "content-type": "application/x-www-form-urlencoded",
    "sec-ch-ua":
    "\" Not A;Brand\";v=\"99\", \"Chromium\";v=\"99\", \"Microsoft Edge\";v=\"99\"",
    "sec-ch-ua-mobile": "?1",
    "sec-ch-ua-platform": "\"Android\"",
    "sec-fetch-dest": "empty",
    "sec-fetch-mode": "cors",
    "sec-fetch-site": "same-origin",
    "token-no": "aa8c6985a8706a7f335354884135e92c",
    "cookie": "$cookie",
    "t": "$t",
    "sign": "$sign",
    "Referer": "https://h5.stararknft.art/",
    "Referrer-Policy": "strict-origin-when-cross-origin"
  };
}
