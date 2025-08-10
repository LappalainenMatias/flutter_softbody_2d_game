import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2D rocket game',
      home: Material(child: const MyHomePage()),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  late double _lastTime;
  int frames = 0;
  Atom? follow;

  @override
  void initState() {
    super.initState();
    _lastTime = 0;
    _ticker = createTicker((elapsed) {
      final dt = (elapsed.inMicroseconds / 1e6) - _lastTime;
      _lastTime = elapsed.inMicroseconds / 1e6;
      frames++;
      simulation.simulate(dt);
      if (follow != null) {
        camera.centerAtom(follow!);
      }
      setState(() {});
    })
      ..start();
    initShader();
  }

  FragmentProgram? program;

  Future<void> initShader() async {
    program = await FragmentProgram.fromAsset('shaders/stars.frag');
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  final simulation = Simulation();
  final camera = Camera();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFF0B0B0B),
      child: Stack(
        children: [
          GestureDetector(
            onTapDown: (details) {
              if (simulation.action == Action.removePoint) {
                simulation.removeAtom(
                  camera.screenToWorldX(details.localPosition.dx),
                  camera.screenToWorldY(details.localPosition.dy),
                );
              } else if (simulation.action == Action.addPoint) {
                simulation.addAtom(
                  camera.screenToWorldX(details.localPosition.dx),
                  camera.screenToWorldY(details.localPosition.dy),
                );
              } else if (simulation.action == Action.connectPoints) {
                simulation.connect(
                  camera.screenToWorldX(details.localPosition.dx),
                  camera.screenToWorldY(details.localPosition.dy),
                );
              } else if (simulation.action == Action.increaseConnection) {
                simulation.changeConnection(
                  camera.screenToWorldX(details.localPosition.dx),
                  camera.screenToWorldY(details.localPosition.dy),
                  50,
                );
              } else if (simulation.action == Action.decreaseConnection) {
                simulation.changeConnection(
                  camera.screenToWorldX(details.localPosition.dx),
                  camera.screenToWorldY(details.localPosition.dy),
                  -50,
                );
              } else if (simulation.action == Action.addEngine) {
                simulation.addEngine(
                  camera.screenToWorldX(details.localPosition.dx),
                  camera.screenToWorldY(details.localPosition.dy),
                );
              } else if (simulation.action == Action.followPoint) {
                final Atom? atom = simulation._findClosestAtom(
                  camera.screenToWorldX(details.localPosition.dx),
                  camera.screenToWorldY(details.localPosition.dy),
                );
                if (atom != null) {
                  follow = atom;
                }
                simulation.action = null;
              }
            },
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width,
                  MediaQuery.of(context).size.height), // Full screen size
              painter: SimulationCustomPainter(simulation, camera, program),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Container(
                  color: Color(0xB3000000),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                        "Record: ${-1 * simulation.recordHeight.toInt()}\n"
                        "Current: ${-1 * simulation.currentHeight.toInt()}",
                        style: TextStyle(fontSize: 20, color: Colors.white)),
                  )),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          simulation.frozen = !simulation.frozen;
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            style: TextStyle(
                                color: !simulation.frozen
                                    ? Colors.green
                                    : Colors.red),
                            simulation.frozen
                                ? "Resume simulation"
                                : "Pause simulation",
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          simulation.gravity = !simulation.gravity;
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            style: TextStyle(
                                color: simulation.gravity
                                    ? Colors.green
                                    : Colors.red),
                            simulation.gravity
                                ? "Pause Gravity"
                                : "Resume Gravity",
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          if (simulation.action == Action.addPoint) {
                            simulation.action = null;
                          } else {
                            simulation.action = Action.addPoint;
                          }
                        },
                        child: Text("Add point",
                            style: TextStyle(
                              color: simulation.action == Action.addPoint
                                  ? Colors.green
                                  : Colors.black,
                            )),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          if (simulation.action == Action.removePoint) {
                            simulation.action = null;
                          } else {
                            simulation.action = Action.removePoint;
                          }
                        },
                        child: Text(
                          "Remove point",
                          style: TextStyle(
                            color: simulation.action == Action.removePoint
                                ? Colors.green
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          if (simulation.action == Action.connectPoints) {
                            simulation.action = null;
                          } else {
                            simulation.action = Action.connectPoints;
                          }
                        },
                        child: Text("Add connection",
                            style: TextStyle(
                                color: simulation.action == Action.connectPoints
                                    ? Colors.green
                                    : Colors.black)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                          onPressed: () {
                            if (simulation.action ==
                                Action.increaseConnection) {
                              simulation.action = null;
                            } else {
                              simulation.action = Action.increaseConnection;
                            }
                          },
                          child: Text(
                            "Loosen Connection",
                            style: TextStyle(
                                color: simulation.action ==
                                        Action.increaseConnection
                                    ? Colors.green
                                    : Colors.black),
                          )),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          if (simulation.action == Action.decreaseConnection) {
                            simulation.action = null;
                          } else {
                            simulation.action = Action.decreaseConnection;
                          }
                        },
                        child: Text(
                          "Tighten connection",
                          style: TextStyle(
                              color:
                                  simulation.action == Action.decreaseConnection
                                      ? Colors.green
                                      : Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          if (simulation.action == Action.addEngine) {
                            simulation.action = null;
                          } else {
                            simulation.action = Action.addEngine;
                          }
                        },
                        child: Text(
                          "Add engines",
                          style: TextStyle(
                            color: simulation.action == Action.addEngine
                                ? Colors.green
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          simulation.isEngineOn = !simulation.isEngineOn;
                        },
                        child: Row(
                          children: [
                            Icon(
                              Icons.local_fire_department_outlined,
                              color: simulation.isEngineOn
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            Text(
                              simulation.isEngineOn
                                  ? "Stop engines"
                                  : "Start engines",
                              style: TextStyle(
                                color: simulation.isEngineOn
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          simulation.action = null;
                          for (var atomPair in simulation.atomPairs) {
                            atomPair.motor = null;
                          }
                        },
                        child: Text("Remove engines",
                            style: TextStyle(
                              color: Colors.black,
                            )),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor:
                          follow != null ? Colors.green : Colors.black,
                    ),
                    onPressed: () {
                      if (follow != null) {
                        follow = null;
                        simulation.action = null;
                      } else {
                        simulation.action = Action.followPoint;
                      }
                    },
                    child: Text(
                      "Center camera to point",
                      style: TextStyle(
                        color: follow != null ||
                                simulation.action == Action.followPoint
                            ? Colors.green
                            : Colors.black,
                      ),
                    ),
                  ),
                ),
                // move camera
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FloatingActionButton(
                    child: Icon(Icons.keyboard_arrow_up_sharp),
                    onPressed: () {
                      camera.moveUp();
                    },
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: FloatingActionButton(
                        child: Icon(Icons.keyboard_arrow_left_sharp),
                        onPressed: () {
                          camera.moveLeft();
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: FloatingActionButton(
                        child: Icon(Icons.keyboard_arrow_down_sharp),
                        onPressed: () {
                          camera.moveDown();
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: FloatingActionButton(
                        child: Icon(Icons.keyboard_arrow_right_sharp),
                        onPressed: () {
                          camera.moveRight();
                        },
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                  color: Color(0xB3000000),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "cenX: ${camera.cenX.toStringAsFixed(2)}\n"
                      "cenY: ${camera.cenY.toStringAsFixed(2)}\n"
                      "action: ${simulation.action}\n"
                      "frames: $frames",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  )),
            ),
          ),
        ],
      ),
    );
  }
}

enum Action {
  addPoint,
  removePoint,
  connectPoints,
  decreaseConnection,
  increaseConnection,
  addEngine,
  followPoint
}

class Camera {
  double cenX = 0.0;
  double cenY = -200.0;
  double width = 1000.0;
  double height = 1000.0;

  double screenToWorldX(double x) {
    return cenX - width / 2 + x / width * width;
  }

  double screenToWorldY(double y) {
    return cenY - height / 2 + y / height * height;
  }

  void zoomIn() {
    width *= 0.85;
    height *= 0.85;
  }

  void zoomOut() {
    width /= 0.85;
    height /= 0.85;
  }

  void moveUp() {
    cenY -= height / 10;
  }

  void moveDown() {
    cenY += height / 10;
  }

  void moveLeft() {
    cenX -= width / 10;
  }

  void moveRight() {
    cenX += width / 10;
  }

  void centerAtom(Atom atom) {
    cenX = atom.cenX;
    cenY = atom.cenY;
  }
}

class SimulationCustomPainter extends CustomPainter {
  final Simulation simulation;
  final Camera camera;
  final FragmentProgram? program;

  SimulationCustomPainter(this.simulation, this.camera, this.program);

  @override
  void paint(Canvas canvas, Size size) {
    camera.width = size.width;
    camera.height = size.height;
    canvas.translate(
      size.width / 2 - camera.cenX,
      size.height / 2 - camera.cenY,
    );
    canvas.scale(size.width / camera.width, size.height / camera.height);

    // ground is positive y
    var paint = Paint();
    paint.color = Color.fromARGB(255, 100, 100, 100);
    Rect groundRect = Rect.fromLTRB(-10000, 0, 10000, 10000);
    canvas.drawRect(groundRect, paint);

    for (final atomPair in simulation.atomPairs) {
      final path = Path();
      paint.color = Color.fromARGB(
          255,
          max(0, 255 - (atomPair.connectionStrength / 2.0).toInt()),
          min(255, (atomPair.connectionStrength / 2.0).toInt()),
          100);
      path.moveTo(atomPair.atom1.cenX, atomPair.atom1.cenY);
      path.lineTo(atomPair.atom2.cenX, atomPair.atom2.cenY);
      paint.strokeWidth = 6;
      canvas.drawPath(path, paint);
      canvas.drawLine(Offset(atomPair.atom1.cenX, atomPair.atom1.cenY),
          Offset(atomPair.atom2.cenX, atomPair.atom2.cenY), paint);
    }

    for (final atomPair in simulation.atomPairs) {
      if (atomPair.motor != null) {
        paint.color = Colors.orange;
        canvas.drawLine(
          Offset(
              atomPair.motor!.startAtom.cenX, atomPair.motor!.startAtom.cenY),
          Offset(
              (atomPair.motor!.startAtom.cenX + atomPair.motor!.endAtom.cenX) /
                  2,
              (atomPair.motor!.startAtom.cenY + atomPair.motor!.endAtom.cenY) /
                  2),
          paint,
        );
      }
    }

    for (final atom in simulation.atoms) {
      paint.color = Color.fromARGB(255, 0, 131, 239);
      canvas.drawCircle(Offset(atom.cenX, atom.cenY), 18, paint);
    }

    for (final particle in simulation.particles) {
      paint.color = Color.fromARGB(255, 207, 35, 6);
      canvas.drawCircle(Offset(particle.cenX, particle.cenY), 5, paint);
    }

    if (simulation.connectStart != null) {
      paint.color = Color.fromARGB(255, 1, 221, 250);
      canvas.drawCircle(
        Offset(simulation.connectStart!.cenX, simulation.connectStart!.cenY),
        18,
        paint,
      );
    }
    if (simulation.connectEnd != null) {
      paint.color = Color.fromARGB(255, 1, 221, 250);
      canvas.drawCircle(
        Offset(simulation.connectEnd!.cenX, simulation.connectEnd!.cenY),
        18,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class Simulation {
  bool frozen = false;
  bool gravity = false;
  bool isEngineOn = false;
  double? mouseX = 0.0;
  double? mouseY = 0.0;
  Atom? selectedAtom;
  Action? action;
  Atom? connectStart;
  Atom? connectEnd;
  List<Atom> atoms = [];
  List<AtomPair> atomPairs = [];
  List<Particle> particles = [];
  double recordHeight = 0;
  double currentHeight = 0;

  void simulate(double dt) {
    if (action != Action.connectPoints &&
        action != Action.decreaseConnection &&
        action != Action.increaseConnection &&
        action != Action.addEngine) {
      connectStart = null;
      connectEnd = null;
    }
    if (!frozen) {
      dt = min(dt, 0.016 * 10);
      _atomForces(dt);
      if (gravity) _gravity(dt);
      _friction(dt);
      if (isEngineOn) _motorForces(dt);
      _updateAtoms(dt);
      _updateParticles(dt);
      if (isEngineOn) _addParticles(dt);
      if (gravity) _updateRecord();
      if (gravity) _updateCurrent();
    }
  }

  void _updateRecord() {
    if (currentHeight < recordHeight) {
      recordHeight = currentHeight;
    }
  }

  void _updateCurrent() {
    if (atoms.isEmpty) return;
    double lowest = atoms.first.cenY;
    for (final atom in atoms) {
      if (atom.cenY > lowest) {
        lowest = atom.cenY;
      }
    }
    currentHeight = lowest;
  }

  void _motorForces(double dt) {
    for (final atomPair in atomPairs) {
      if (atomPair.motor == null) {
        continue;
      }

      final Motor motor = atomPair.motor!;

      final dx = motor.startAtom.cenX - motor.endAtom.cenX;
      final dy = motor.startAtom.cenY - motor.endAtom.cenY;
      final distance = sqrt(dx * dx + dy * dy);
      if (distance == 0) {
        continue;
      }

      final motorForce = motor.force;

      final normalizedDx = dx / distance;
      final normalizedDy = dy / distance;

      motor.startAtom.velocityX -= motorForce * normalizedDx * dt;
      motor.startAtom.velocityY -= motorForce * normalizedDy * dt;

      motor.fuel -= dt;
      if (motor.fuel < 0) {
        atomPair.motor = null;
      }
    }
  }

  void _friction(double dt) {
    for (final atom in atoms) {
      atom.velocityX *= 1.0 - dt * 4;
      atom.velocityY *= 1.0 - dt * 4;
    }
  }

  void _updateAtoms(double dt) {
    for (final atom in atoms) {
      atom.cenX += atom.velocityX * dt;
      atom.cenY += atom.velocityY * dt;
      if (atom.cenY > 0) {
        atom.cenY = 0;
        atom.velocityY = 0;
      }
    }
  }

  void _addParticles(double dt) {
    final random = Random();
    // Creates more particles
    for (final pair in atomPairs) {
      if (pair.motor == null) {
        continue;
      } else {
        final Motor motor = pair.motor!;

        // Calculate direction vector from startAtom to endAtom
        final dx = motor.startAtom.cenX - motor.endAtom.cenX;
        final dy = motor.startAtom.cenY - motor.endAtom.cenY;

        // Reverse the direction to shoot particles in the opposite direction
        final reversedDx = dx * 2; // Reverse direction on X axis
        final reversedDy = dy * 2; // Reverse direction on Y axis

        // Add random noise to the direction
        final rdx =
            random.nextDouble() * 60 - 30; // Random X offset between -30 and 30
        final rdy =
            random.nextDouble() * 60 - 30; // Random Y offset between -30 and 30

        // Create the particle and add it to the list
        particles.add(Particle(motor.startAtom.cenX, motor.startAtom.cenY,
            reversedDx + rdx, reversedDy + rdy));
      }
    }
  }

  void _updateParticles(double dt) {
    for (final particle in particles) {
      particle.cenX += particle.velocityX * dt;
      particle.cenY += particle.velocityY * dt;
      particle.timeLeft -= dt;
    }

    particles.removeWhere((element) => element.timeLeft < 0);
  }

  void _atomForces(double dt) {
    for (final atomPair in atomPairs) {
      final force = atomPair.connectionStrength * dt;
      final dx = atomPair.atom1.cenX - atomPair.atom2.cenX;
      final dy = atomPair.atom1.cenY - atomPair.atom2.cenY;
      final d = sqrt(dx * dx + dy * dy);

      final nx = dx / d;
      final ny = dy / d;

      final deltaX = nx * (d - atomPair.connectionStrength) / 4;
      final deltaY = ny * (d - atomPair.connectionStrength) / 4;

      atomPair.atom1.velocityX -= deltaX * force;
      atomPair.atom1.velocityY -= deltaY * force;
      atomPair.atom2.velocityX += deltaX * force;
      atomPair.atom2.velocityY += deltaY * force;
    }
  }

  void _gravity(double dt) {
    for (final atom in atoms) {
      atom.velocityY += 9.8 * dt * 200;
    }
  }

  void removeAtom(double worldX, double worldY) {
    if (kDebugMode) {
      print("trying to remove atom at $worldX, $worldY");
    }
    Atom? closestAtom = _findClosestAtom(worldX, worldY);
    if (closestAtom == null) {
      return;
    }
    final dx = closestAtom.cenX - worldX;
    final dy = closestAtom.cenY - worldY;
    final closestDistance = sqrt(dx * dx + dy * dy);
    if (closestDistance < 25) {
      atoms.remove(closestAtom);
      atomPairs.removeWhere((element) =>
          element.atom1 == closestAtom || element.atom2 == closestAtom);
    }
  }

  Atom? _findClosestAtom(double worldX, double worldY) {
    Atom? closestAtom;
    var closestDistance = double.infinity;
    for (final atom in atoms) {
      final dx = atom.cenX - worldX;
      final dy = atom.cenY - worldY;
      final distance = sqrt(dx * dx + dy * dy);
      if (distance < closestDistance) {
        closestAtom = atom;
        closestDistance = distance;
      }
    }
    return closestAtom;
  }

  void addAtom(double worldX, double worldY) {
    atoms.add(Atom(worldX, worldY));
  }

  void addEngine(double worldX, double worldY) {
    if (connectStart == null || connectEnd == null) {
      Atom? closestAtom = _findClosestAtom(worldX, worldY);
      if (closestAtom == null) {
        return;
      }
      final dx = closestAtom.cenX - worldX;
      final dy = closestAtom.cenY - worldY;
      final closestDistance = sqrt(dx * dx + dy * dy);
      if (closestDistance > 25) {
        return;
      }
      if (connectStart == null) {
        connectStart = closestAtom;
      } else {
        connectEnd = closestAtom;
      }
    }

    if (connectStart == connectEnd) {
      connectStart = null;
      connectEnd = null;
      return;
    }

    if (connectStart != null && connectEnd != null) {
      AtomPair? match;
      for (final atomPair in atomPairs) {
        if (atomPair.atom1 == connectStart && atomPair.atom2 == connectEnd) {
          match = atomPair;
          break;
        }
        if (atomPair.atom2 == connectStart && atomPair.atom1 == connectEnd) {
          match = atomPair;
          break;
        }
      }
      if (match != null) {
        match.motor = Motor(3000, connectStart!, connectEnd!);
      }
      connectStart = null;
      connectEnd = null;
    }
  }

  void changeConnection(double worldX, double worldY, double change) {
    if (connectStart == null || connectEnd == null) {
      Atom? closestAtom = _findClosestAtom(worldX, worldY);
      if (closestAtom == null) {
        return;
      }
      final dx = closestAtom.cenX - worldX;
      final dy = closestAtom.cenY - worldY;
      final closestDistance = sqrt(dx * dx + dy * dy);
      if (closestDistance > 25) {
        return;
      }
      if (connectStart == null) {
        connectStart = closestAtom;
      } else {
        connectEnd = closestAtom;
      }
    }

    if (connectStart == connectEnd) {
      connectStart = null;
      connectEnd = null;
      return;
    }

    if (connectStart != null && connectEnd != null) {
      AtomPair? match;
      for (final atomPair in atomPairs) {
        if (atomPair.atom1 == connectStart && atomPair.atom2 == connectEnd) {
          match = atomPair;
          break;
        }
        if (atomPair.atom2 == connectStart && atomPair.atom1 == connectEnd) {
          match = atomPair;
          break;
        }
      }
      if (match != null) {
        match.changeConnectionStrength(change);
      }
      connectStart = null;
      connectEnd = null;
    }
  }

  void connect(double worldX, double worldY) {
    if (connectStart == null || connectEnd == null) {
      Atom? closestAtom = _findClosestAtom(worldX, worldY);
      if (closestAtom == null) {
        return;
      }
      final dx = closestAtom.cenX - worldX;
      final dy = closestAtom.cenY - worldY;
      final closestDistance = sqrt(dx * dx + dy * dy);
      if (closestDistance > 25) {
        return;
      }
      if (connectStart == null) {
        connectStart = closestAtom;
      } else {
        connectEnd = closestAtom;
      }
    }

    if (connectStart == connectEnd) {
      connectStart = null;
      connectEnd = null;
      return;
    }

    if (connectStart != null && connectEnd != null) {
      // removed dublicate connections first
      atomPairs.removeWhere((element) =>
          element.atom1 == connectStart && element.atom2 == connectStart);
      atomPairs.removeWhere((element) =>
          element.atom2 == connectStart && element.atom1 == connectStart);
      atomPairs.add(AtomPair(connectStart!, connectEnd!));
      connectStart = null;
      connectEnd = null;
    }
  }
}

class Particle {
  double cenX;
  double cenY;
  double velocityX;
  double velocityY;
  double timeLeft = 2;

  Particle(this.cenX, this.cenY, this.velocityX, this.velocityY);
}

class Atom {
  double cenX;
  double cenY;
  double velocityX = 0;
  double velocityY = 0;

  Atom(this.cenX, this.cenY);
}

class Motor {
  final double force;
  double fuel = 6.0;
  final Atom startAtom;
  final Atom endAtom;

  Motor(this.force, this.startAtom, this.endAtom);
}

class AtomPair {
  final Atom atom1;
  final Atom atom2;

  // Motor pushes atom1 with motor force towards atom2;
  Motor? motor;
  double _connectionStrength = 200; // big is weak
  void changeConnectionStrength(double amount) {
    _connectionStrength += amount;
    if (_connectionStrength < 50) {
      _connectionStrength = 50;
    }
    if (_connectionStrength > 500) {
      _connectionStrength = 500;
    }
  }

  double get connectionStrength => _connectionStrength;

  AtomPair(this.atom1, this.atom2);
}
