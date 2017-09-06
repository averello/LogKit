//
//  InMemoryLog.swift
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

// in-memory
final public class InMemoryLog: Log {
    final private var logs: [TextRepresentation]

    public init() {
        self.logs = []
    }

    final public func put(entry: Representable) {
        let representation = entry.represent(using: LogRepresentation()) as! TextRepresentation
        self.logs.append(representation)
    }

    final public func represent(using representation: Representation) -> Representation {
        return self.logs.reduce(representation) { (rep, r) -> Representation in
            rep.with(key: TextKey(), value: r.content)
        }
    }
}
