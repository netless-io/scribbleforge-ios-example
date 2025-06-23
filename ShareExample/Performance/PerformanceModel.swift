import BenchmarkKit
import Foundation
import NTLBridge
import ScribbleForge
import WebKit
import YSwift

func generateBigData(count: Int) -> (String, Data) {
    let ydoc = YContext().createDoc()
    for id in 0 ..< count {
        let map = ydoc.getMap(id: "@app/whiteboard/ImageryDoc220037_wb/user/\(id)")
        map.set(key: "permission", value: 127)
        map.set(key: "themeColor", value: "#009688")
        map.set(key: "viewMatrix", value: "1,2324324")
        map.set(key: "cameraMode", value: "main")
        map.set(key: "tool", value: "rectangle")
        map.set(key: "strokeColor", value: "#009688")
        map.set(key: "fillColor", value: "1")
        map.set(key: "fontSize", value: 24)
        map.set(key: "fontFamily", value: "Courier New")
        map.set(key: "strokeWidth", value: 4)
        map.set(key: "dashArray", value: "sdfsdf")
        map.set(key: "currentPage", value: "_i_")
        map.set(key: "shadowActive", value: false)
    }
    let update = ydoc.yContext.encodeStateAsUpdate(doc: ydoc)
    let itemCount = ydoc.yContext.jsContext.evaluateScript("Array.from(__doc.store.clients.values()).reduce((acc, client) => acc + client.length, 0)").toNumber().intValue
    return ("Items: \(itemCount) \nSize: \(update.count / 1024) KB", update)
}

struct PerformanceModel {
    let datas: [String: Data]
    let queue: DispatchQueue
    let times: Int

    init(times: Int, queue: DispatchQueue = .main) {
        self.times = times
        self.queue = queue

//        let p1 = Bundle.main.path(forResource: "1746696154954", ofType: "snapshot")!
//        let u1 = URL(fileURLWithPath: p1)
//        let data = try! Data(contentsOf: u1)
//        datas = [
//            "test": data,
//        ]

//        let p1 = Bundle.main.path(forResource: "test", ofType: "ydoc")!
//        let u1 = URL(fileURLWithPath: p1)
//        let data = try! Data(contentsOf: u1)
//        datas = [
//            "test": data,
//        ]

        let values = [100, 500, 1000].map { generateBigData(count: $0) }
//        let values = [100, 500, 1000, 3000].map { generateBigData(count: $0) }
        datas = .init(uniqueKeysWithValues: values)
    }

    func perform() async -> [MeasureResult] {
        for (key, data) in datas {
            BenchmarkKit.measureWork(
                MeasureInput<YDoc>(
                    taskName: "Apply",
                    impLabel: "JSC",
                    resourceCaseLabel: key,
                    performQueue: queue,
                    performTimes: times,
                    prepare: { prepareDoneCallback in
                        let context = YContext()
                        let doc = context.createDoc()
                        prepareDoneCallback(doc)
                    },
                    syncWork: { doc in
                        doc.yContext.applyUpdate(doc: doc, buf: data)
                    },
                    finishedHandler: { _ in
                    }
                )
            )

            BenchmarkKit.measureWork(
                MeasureInput<YDocument>(
                    taskName: "Apply",
                    impLabel: "yrs",
                    resourceCaseLabel: key,
                    performQueue: queue,
                    performTimes: times,
                    prepare: { prepareDoneCallback in
                        prepareDoneCallback(YDocument())
                    },
                    syncWork: { doc in
                        doc.transactSync { txn in
                            try! txn.transactionApplyUpdate(update: [UInt8](data))
                        }
                    },
                    finishedHandler: { _ in
                    }
                )
            )

            BenchmarkKit.measureWork(
                MeasureInput<(NTLDWKWebView, [UInt8])>(
                    taskName: "Apply",
                    impLabel: "WK",
                    resourceCaseLabel: key,
                    performQueue: queue,
                    performTimes: times,
                    prepare: { prepareDoneCallback in
                        DispatchQueue.main.async {
                            let wkwebView = NTLDWKWebView()
                            wkwebView.isInspectable = true
                            wkwebView.load(.init(url: .init(string: localWhiteboardSrc)!))
                            UIApplication.shared.keyWindow?.addSubview(wkwebView)
                            wkwebView.callHandler("prepareApp", arguments: [["appId": "", "userId": ""]] as? [Any]) { _ in
                                let dataArray = [UInt8](data)
                                prepareDoneCallback((wkwebView, dataArray))
                            }
                        }
                    },
                    asyncWork: { input, done in
                        let webView = input.0
                        let dataArray = input.1
                        webView.callHandler("doc.update", arguments: [dataArray, ""]) { _ in
                            done()
                            webView.removeFromSuperview()
                        }
                    },
                    finishedHandler: { _ in
                    }
                )
            )

            BenchmarkKit.measureWork(
                MeasureInput<Void>(
                    taskName: "Convert",
                    impLabel: "Data2Int",
                    resourceCaseLabel: key,
                    performQueue: queue,
                    performTimes: times,
                    prepare: { prepareDoneCallback in
                        prepareDoneCallback(())
                    },
                    syncWork: { _ in
                        _ = [UInt8](data)
                    },
                    finishedHandler: { _ in
                    }
                )
            )
            BenchmarkKit.measureWork(
                MeasureInput<YDocument>(
                    taskName: "Encode",
                    impLabel: "yrs",
                    resourceCaseLabel: key,
                    performQueue: queue,
                    performTimes: times,
                    prepare: { prepareDoneCallback in
                        let doc = YDocument()
                        doc.transactSync { txn in
                            try! txn.transactionApplyUpdate(update: [UInt8](data))
                        }
                        prepareDoneCallback(doc)
                    },
                    syncWork: { doc in
                        _ = doc.transactSync { txn in
                            txn.transactionEncodeStateAsUpdate()
                        }
                        return ()
                    },
                    finishedHandler: { _ in
                    }
                )
            )

            BenchmarkKit.measureWork(
                MeasureInput<YDoc>(
                    taskName: "Encode",
                    impLabel: "JSC",
                    resourceCaseLabel: key,
                    performQueue: queue,
                    performTimes: times,
                    prepare: { prepareDoneCallback in
                        let doc = YContext().createDoc()
                        doc.yContext.applyUpdate(doc: doc, buf: data)
                        prepareDoneCallback(doc)
                    },
                    syncWork: { doc in
                        _ = doc.yContext.encodeStateAsUpdate(doc: doc)
                    },
                    finishedHandler: { _ in
                    }
                )
            )

            BenchmarkKit.measureWork(
                MeasureInput<YDoc>(
                    taskName: "Encode",
                    impLabel: "JSC(Pure)",
                    resourceCaseLabel: key,
                    performQueue: queue,
                    performTimes: times,
                    prepare: { prepareDoneCallback in
                        let doc = YContext().createDoc()
                        doc.yContext.applyUpdate(doc: doc, buf: data)
                        prepareDoneCallback(doc)
                    },
                    syncWork: { doc in
                        doc.context.evaluateScript("doY.doY.encodeStateAsUpdate(__doc)")
                    },
                    finishedHandler: { _ in
                    }
                )
            )

            BenchmarkKit.measureWork(
                MeasureInput<(YDoc, YDoc)>(
                    taskName: "Sync",
                    impLabel: "JSC-JSC",
                    resourceCaseLabel: key,
                    performQueue: queue,
                    performTimes: times,
                    prepare: { prepareDoneCallback in
                        let doc = YContext().createDoc()
                        doc.yContext.applyUpdate(doc: doc, buf: data)

                        let doc2 = YContext().createDoc()
                        prepareDoneCallback((doc, doc2))
                    },
                    syncWork: { doc, doc2 in
                        let docData = doc.yContext.encodeStateAsUpdate(doc: doc)
                        doc2.yContext.applyUpdate(doc: doc2, buf: docData)
                    },
                    finishedHandler: { _ in
                    }
                )
            )

            BenchmarkKit.measureWork(
                MeasureInput<(YDoc, YDoc, Data)>(
                    taskName: "Sync",
                    impLabel: "JSC-JSC(Step)",
                    resourceCaseLabel: key,
                    performQueue: queue,
                    performTimes: times,
                    prepare: { prepareDoneCallback in
                        let doc = YContext().createDoc()
                        doc.yContext.applyUpdate(doc: doc, buf: data)
                        let docData = doc.yContext.encodeStateAsUpdate(doc: doc)

                        let doc2 = YContext().createDoc()
                        let old = doc.yContext.encodeStateAsUpdate(doc: doc)
                        for i in 0 ..< 100 {
                            doc.getMap(id: "step_\(i)").set(key: "step", value: i)
                        }
                        prepareDoneCallback((doc, doc2, docData))
                    },
                    syncWork: { doc, doc2, docData in
                        doc2.yContext.applyUpdate(doc: doc2, buf: docData)
                        let doc2Vector = doc2.yContext.encodeStateVector(doc: doc2)

                        let diffFromDoc = doc.yContext.encodeStateAsUpdate(doc: doc, encodedTargetVector: doc2Vector)
                        doc2.yContext.applyUpdate(doc: doc2, buf: diffFromDoc)
                    },
                    finishedHandler: { _ in
                    }
                )
            )

            BenchmarkKit.measureWork(
                MeasureInput<NTLDWKWebView>(
                    taskName: "Encode",
                    impLabel: "WK",
                    resourceCaseLabel: key,
                    performQueue: queue,
                    performTimes: times,
                    prepare: { prepareDoneCallback in
                        DispatchQueue.main.async {
                            let wkwebView = NTLDWKWebView()
                            wkwebView.isInspectable = true
                            wkwebView.load(.init(url: .init(string: localWhiteboardSrc)!))
                            UIApplication.shared.keyWindow?.addSubview(wkwebView)
                            let dataArray = [UInt8](data)
                            wkwebView.callHandler("doc.update", arguments: [dataArray, ""]) { _ in
                                prepareDoneCallback(wkwebView)
                            }
                        }
                    },
                    asyncWork: { webView, done in
                        webView.evaluateJavaScript("window.encodeDoc()") { _, _ in
                            done()
                            webView.removeFromSuperview()
                        }
                    },
                    finishedHandler: { _ in
                    }
                )
            )
        }

        let results = await BenchmarkKit.main()
        print(BenchmarkKit.report(results: results))
        return results
    }
}
