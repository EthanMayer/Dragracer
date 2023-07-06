//
//  Barometer.swift
//  DragRacer
//
//  Created by Ethan Mayer and Sebastian Bond on 6/13/19.
//  Copyright © 2019 Ethan Mayer and Sebastian Bond. All rights reserved.
//

import Foundation
import CoreMotion
import Combine
import SwiftUILogger

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}

// Async stream implementation for debugging
class Barometer {
    
    // Initialize pressure sensor
    let altimeter = CMAltimeter()
    
    var pressure = 0.0

    // Get the current pressure from the barometer, return as Future
    func getPressure() -> AsyncThrowingStream<Double, Error> {
        return AsyncThrowingStream<Double, Error> { continuation in
            
            // Proceed async
            DispatchQueue.main.async {
        
                // Check if altimeter is working
                if CMAltimeter.isRelativeAltitudeAvailable() {
                    
                    // Check authorization status of altimeter
                    switch CMAltimeter.authorizationStatus() {
                        case .notDetermined: // Handle state before user prompt
                            logger.log(level: .info, message: "Altimiter authorization undetermined")
                        case .restricted: // Handle system-wide restriction
                            continuation.finish(throwing: "Altimeter authorization restricted")
                        case .denied: // Handle user denied state
                            continuation.finish(throwing: "Altimeter authorization denied")
                        case .authorized: // Ready to go!
                            logger.log(level: .info, message: "Altimeter authorized")
                        @unknown default:
                            continuation.finish(throwing: "Unknown authorization status")
                    }
                    
                    // Start receiving altitude from altimeter
                    self.altimeter.startRelativeAltitudeUpdates(to: OperationQueue.main) { (data, error) in
                        
                        // If there is a non-nil error, return with promise as failure
                        if let error = error {
                            continuation.finish(throwing: error)
                            
                        // If there is no error, proceed
                        } else {
                            
                            // Get pressure in inHg
                            self.pressure = Measurement(value: (data?.pressure.doubleValue)!, unit: UnitPressure.kilopascals)/*.converted(to: .inchesOfMercury)*/.value
                            
//                            logger.log(level: .debug, message: "Pressure: " + String(self.pressure))
                            continuation.yield(self.pressure)
                            
                            // Stop receiving updates after the pressure has been recorded
                            self.altimeter.stopRelativeAltitudeUpdates()
                            
                            // Return value with promise as success
//                            promise(.success(self.pressure))
                        }
                    }
                }
                else {
                    continuation.finish(throwing: "Relative altitude is unavailable")
                }
            }
        }
    }
}


/* Future implementation below
class Barometer {
    
    // Initialize pressure sensor
    let altimeter = CMAltimeter()
    
    var pressure = 0.0

    // Get the current pressure from the barometer, return as Future
    func getPressure() -> Future<Double, Error> {
        return Future<Double, Error> { promise in
            
            // Proceed async
            DispatchQueue.main.async {
        
                // Check if altimeter is working
                if CMAltimeter.isRelativeAltitudeAvailable() {
                    
                    // Check authorization status of altimeter
                    switch CMAltimeter.authorizationStatus() {
                        case .notDetermined: // Handle state before user prompt
                            logger.log(level: .info, message: "Altimiter authorization undetermined")
                        case .restricted: // Handle system-wide restriction
                            promise(.failure("Altimeter authorization restricted"))
                        case .denied: // Handle user denied state
                            promise(.failure("Altimeter authorization denied"))
                        case .authorized: // Ready to go!
                            logger.log(level: .info, message: "Altimeter authorized")
                        @unknown default:
                            promise(.failure("Unknown authorization status"))
                    }
                    
                    // Start receiving altitude from altimeter
                    self.altimeter.startRelativeAltitudeUpdates(to: OperationQueue.main) { (data, error) in
                        
                        // If there is a non-nil error, return with promise as failure
                        if let error = error {
                            promise(.failure(error))
                            
                        // If there is no error, proceed
                        } else {
                            
                            // Get pressure in inHg
                            self.pressure = Measurement(value: (data?.pressure.doubleValue)!, unit: UnitPressure.kilopascals)/*.converted(to: .inchesOfMercury)*/.value
                            
                            logger.log(level: .debug, message: "Pressure: " + String(self.pressure))
                            
                            // Stop receiving updates after the pressure has been recorded
                            self.altimeter.stopRelativeAltitudeUpdates()
                            
                            // Return value with promise as success
                            promise(.success(self.pressure))
                        }
                    }
                }
            }
        }
    }
}
*/
