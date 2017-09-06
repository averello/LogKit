//
//  OnDiskLog.swift
//  LogKit
//
//  Created by Georges Boumis on 07/10/2016.
//
//  Licensed to the Apache Software Foundation (ASF) under one
//  or more contributor license agreements.  See the NOTICE file
//  distributed with this work for additional information
//  regarding copyright ownership.  The ASF licenses this file
//  to you under the Apache License, Version 2.0 (the
//  "License"); you may not use this file except in compliance
//  with the License.  You may obtain a copy of the License at
//  
//    http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the License is distributed on an
//  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//  KIND, either express or implied.  See the License for the
//  specific language governing permissions and limitations
//  under the License.
//

import Foundation
import RepresentationKit
import ContentKit

final public class OnDiskLog: Log {
    final fileprivate let url: URL
    final fileprivate let file: FileHandle
    final fileprivate lazy var path: String = {
       return self.url.path
    }()

    public convenience init(path: String) throws {
        let url = URL(fileURLWithPath: path)
        try self.init(url: url)
    }
    
    public init(url: URL) throws {
        self.url = url
        let path = url.path
        
        let fm = FileManager.default
        if fm.fileExists(atPath: path) == false {
            let directory = url.deletingPathExtension().deletingLastPathComponent()
            try fm.createDirectory(at: directory,
                                   withIntermediateDirectories: true,
                                   attributes: nil)
            let result = fm.createFile(atPath: url.path,
                                       contents: nil,
                                       attributes: nil)
            guard result else {
                throw CocoaError(CocoaError.Code.fileWriteNoPermission)
            }
            // protect the logs
            let attributes = [FileAttributeKey.protectionKey: FileProtectionType.complete]
            try fm.setAttributes(attributes, ofItemAtPath: path)
        }
        self.file = FileHandle(forWritingAtPath: path)!
        self.file.seekToEndOfFile()
    }

    deinit {
        self.file.closeFile()
    }
}

extension OnDiskLog {
    final public func put(entry: Representable) {
        self.queue.async {
            self._useAutoreleasePoolIfNeeded {
                self._put(entry: entry)
            }
        }
    }

    final public func represent(using representation: Representation) -> Representation {
        var result: Representation!
        self.queue.sync {
            self._useAutoreleasePoolIfNeeded {
                result = self._represent(using: representation)
            }
        }
        return result
    }
}

extension OnDiskLog {
    final fileprivate func _useAutoreleasePoolIfNeeded(_ body: () throws -> Void) rethrows {
        if #available(iOS 10.0, *) {
            try body()
        }
        else {
            try autoreleasepool(invoking: body)
        }
    }

    final fileprivate func _put(entry: Representable) {
        let representation = entry.represent(using: LogRepresentation()) as! TextRepresentation
        let content = representation.content
        let data = content.data(using: String.Encoding.utf8)!
        self.file.write(data)
    }

    final fileprivate func _represent(using representation: Representation) -> Representation {
        self.file.synchronizeFile()
        let content = try! String(contentsOfFile: self.path)
        return representation.with(key: TextKey(), value: content)
    }
}


extension OnDiskLog {
    private static let _queue: DispatchQueue = {
        let label = "info.averello.Log.OnDiskLog"
        if #available(iOS 10.0, *) {
            return DispatchQueue(label: label,
                                 qos: DispatchQoS.background,
                                 attributes: DispatchQueue.Attributes(),
                                 autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.workItem,
                                 target: nil)
        } else {
            let attr = __dispatch_queue_attr_make_with_qos_class(nil, QOS_CLASS_BACKGROUND, 0)
            return DispatchQueue(__label: label, attr: attr)
        }
    }()
    final fileprivate var queue: DispatchQueue { return OnDiskLog._queue }
}

extension OnDiskLog: CustomStringConvertible {
    final public var description: String {
        let url = URL(fileURLWithPath: self.path)
        var filename = "\(url.deletingPathExtension().lastPathComponent)"
        if !url.pathExtension.isEmpty {
            filename = filename.appending(".\(url.pathExtension)")
        }
        return "<"
            + String(describing: type(of: self))
            + ": queue = \(self.queue.label);"
            + " path = \(filename);"
            + ">"
    }
}

extension OnDiskLog: CustomDebugStringConvertible {
    final public var debugDescription: String {
        return "<"
            + String(describing: type(of: self))
            + ": \(Unmanaged.passUnretained(self).toOpaque());"
            + " queue = \(self.queue.label);"
            + " path = \(self.path);"
            + ">"
    }
}
