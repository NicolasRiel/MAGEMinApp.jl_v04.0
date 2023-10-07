module MAGEMin_app

using Dash  
using DashBootstrapComponents
using PlotlyJS, JSON3, Printf, Statistics, DataFrames, CSV, Dates, Base64
using UUIDs, HTTP
using Interpolations

# this activate the wrapper of MAGEMin dev branch
#using Pkg
#MAGEMin_dir = "../TC_calibration"
#Pkg.activate(MAGEMin_dir)
#Pkg.instantiate()
using MAGEMin_C

export App

# include helper functions
include("initialize_MAGEMin_AMR.jl")
include("appData.jl")
include("colormaps.jl")
include("Tab_Simulation.jl")
include("Tab_PhaseDiagram.jl")
include("data_plot.jl")
include("MAGEMin_app_functions.jl")
include("Tab_Simulation_Callbacks.jl")    
include("Tab_PhaseDiagram_Callbacks.jl")    



"""
    App(; host = HTTP.Sockets.localhost, port = 8050, max_num_user=10, debug=false)

Starts the MAGEMin App.
"""
function App(; host = HTTP.Sockets.localhost, port = 8050, max_num_user=10, debug=false)
    GUI_version = "0.1.1"   
    cur_dir     = pwd()                 # directory from where you started the GUI
    pkg_dir     = pkgdir(MAGEMin_app)   # package dir
    
    # Initialize MPI and T8Code
    COMM = Initialize_AMR()

    # read available colormaps
    dir_colormaps = joinpath(pkg_dir,"assets/colormaps/")
    colormaps     = read_colormaps(dir_colormaps=dir_colormaps)  # colormaps
    
    app         = dash(external_stylesheets = [dbc_themes.BOOTSTRAP], prevent_initial_callbacks=false)
    app.title   = "MAGEMin app"
    app.layout  = html_div() do
        #data_vert = []
        pkg_dir       = pkgdir(MAGEMin_app)
        dbc_container(fluid=false, [
            dbc_col([
            dbc_row([
                        dbc_col([
                            dbc_cardimg(    id = "jgu-img",
                                            src=    "assets/static/images/JGU_light.jpg",
                                            style = Dict("height" => 90, "width" => 315)),
                                ], width="auto" ),
                        dbc_col([
                            dbc_cardimg(    id = "magemin-img",
                                            src=    "assets/static/images/MAGEMin_light.jpg",
                                            style = Dict("height" => 120, "width" => 360)),
                                ], width="auto" )
                            ], justify="between"),
                    html_div("‎ "),
                    
                    dbc_row([
                            dbc_col([
                                dbc_dropdownmenu(
                                    [dbc_dropdownmenuitem("Load state", disabled=true),
                                    dbc_dropdownmenuitem("Save state", disabled=true),
                                    dbc_dropdownmenuitem(divider=true),
                                    ],
                                    label="File",
                                    id="id-dropdown-file",
                                    color="secondary"),
                                ]),
                            ]),
                            dbc_row([
                                html_div("‎ "),
                            ]),


                            dbc_tabs(
                                [
                                    dbc_tab(    tab_id="tab-Simulation",
                                                label="Simulation",
                                                children = [Tab_Simulation()],
                                            ),
                                    dbc_tab(    tab_id="tab-phase-diagram",
                                                label="Phase Diagram",
                                                children = [Tab_PhaseDiagram(colormaps)]
                                            ),
                                    dbc_tab(tab_id="tab-PTX-path", label="PTX-path",        children = []),
                                    dbc_tab(tab_id="tab-TEmodeling", label="TE-modeling",   children = []),
                
                                ],
                            id = "tabs", active_tab="tab-Simulation",
                            ),

                    ], width=12),

        dcc_store(id="session-id", data =  "")     # gives a unique number of our session

        ])

    end
    
    # This creates an initial session id that is unique for this session
    # it will run on first start 
    callback!(app, 
        Dash.Output("session-id", "data"),
        Dash.Output("label-id", "children"),
        Input("session-id", "data")
    ) do session_id

        session_id = UUIDs.uuid4()
        str = "id=$(session_id), v=$(GUI_version)"
        return String("$(session_id)"), str
    end


    app = Tab_Simulation_Callbacks(app)
    app = Tab_PhaseDiagram_Callbacks(app)

    run_server(app, host, port, debug=true)

    cd(cur_dir) # go back to directory

end



end # module MAGEMin_app

