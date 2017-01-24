module Apps.Embed.Update
    exposing
        ( update
        , initialize
        , onRouteChange
        , Msg(..)
        )

import Navigation
import RemoteData exposing (RemoteData(..))
import Apps.Embed.Model as Model exposing (Model, Tab(..))
import Apps.Embed.Routing as Routing exposing (Route(..))
import Shared.Api as Api
import Types.ApiError as ApiError exposing (ApiError)
import Types.Revision as Revision exposing (Revision)


type Msg
    = NoOp
    | RouteChanged Route
    | LoadRevisionCompleted (Result ApiError Revision)
    | SwitchTab Tab


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SwitchTab tab ->
            ( { model | tab = tab }, Cmd.none )

        LoadRevisionCompleted result ->
            ( { model | revision = RemoteData.fromResult result }
            , Cmd.none
            )

        RouteChanged route ->
            handleRouteChanged route ( { model | currentRoute = route }, Cmd.none )

        _ ->
            ( model, Cmd.none )


onRouteChange : Navigation.Location -> Msg
onRouteChange =
    Routing.parse >> RouteChanged


initialize : Navigation.Location -> ( Model, Cmd Msg )
initialize location =
    let
        initialModel =
            Model.model
    in
        location
            |> Routing.parse
            |> (\route -> { initialModel | currentRoute = route })
            |> (\model -> ( model, Cmd.none ))
            |> (\( model, cmd ) -> handleRouteChanged model.currentRoute ( model, cmd ))



------------------------


loadRevision : String -> Int -> Cmd Msg
loadRevision projectId revisionNumber =
    Api.exactRevision projectId revisionNumber
        |> Api.send LoadRevisionCompleted


handleRouteChanged : Route -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
handleRouteChanged route ( model, cmd ) =
    case route of
        SpecificRevision projectId revisionNumber ->
            ( { model | revision = Loading }
            , Cmd.batch
                [ cmd
                , loadRevision projectId revisionNumber
                ]
            )

        NotFound ->
            ( model
            , cmd
            )
