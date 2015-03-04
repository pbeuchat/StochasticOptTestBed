BRCM TOOLBOX - FILES EDITED BY PAUL BEUCHAT


FILE:                                                   REASON:
                                                        CONVERSION TO THE NEW GRAPHICS OBJECT HANDLES OF MATLAB 2014b
Building.m                                              To allow both types of figure handles
drawBuilding.m                                          To allow both types of figure handles
plot.m                                                  To allow both types of figure handles
SimulationExperiment.m                                  To allow both types of figure handles


                                                        ADJUSTING THE “.csv” PARSER
readCellFromFile.m                                      To convert the text file input to a more standard comma separated parse that actually separates based on commas,
                                                        and ignores commas in a " enclosed data element
loadBuildingElementsData.m                              To handle an input format that has either a string for all vertices for a column for every element of every vertex
checkvertices.m 					To handle an input that is either of the formats that "loadBuildingElementsData.m" has been adapted to handle
Constants.m 						To define a few extra header cell arrays of strings for distinguishing the above vertex input formats

                                                        ADDING OTHER DISCRETISATION OPTIONS
buildingModel.m						Added definition of the "discretised_viaForwardEuler.m" function
discretised_viaForwardEuler.m				New function added that sets the same properties as "discretize.m"
