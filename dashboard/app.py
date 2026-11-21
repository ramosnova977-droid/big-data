"""Dashboard de toxicidad en comentarios (Civil Comments).
Ejecutar:  streamlit run dashboard/app.py   (con la variable DW_URL definida)
"""
import os
import pandas as pd
import plotly.express as px
import streamlit as st
from sqlalchemy import create_engine

st.set_page_config(page_title="Toxicidad en comentarios", layout="wide")

url = os.environ["DW_URL"]
if url.startswith("postgresql://"):
    url = url.replace("postgresql://", "postgresql+psycopg2://", 1)
engine = create_engine(url)


@st.cache_data(ttl=3600)
def cargar():
    q = """SELECT anio, mes, publication_id, rating,
                  COUNT(*) AS comentarios,
                  COALESCE(SUM(indicador_toxico), 0) AS toxicos,
                  COUNT(indicador_toxico) AS validos,
                  COALESCE(SUM(target), 0) AS suma_target,
                  COUNT(target) AS n_target,
                  SUM(likes) AS suma_likes, SUM(disagree) AS suma_disagree
           FROM vw_dashboard
           GROUP BY anio, mes, publication_id, rating"""
    return pd.read_sql(q, engine).dropna(subset=["anio", "mes"])


def pct(t, v):
    return 100 * t / v if v else 0.0


df = cargar()
st.title("Analítica de toxicidad en comentarios (Civil Comments)")
st.caption(f"Volumen cargado en la bodega: {int(df.comentarios.sum()):,} comentarios. "
           "Toxicidad elevada = target >= 0,50 (umbral de la competencia Jigsaw). "
           "No se muestran textos de comentarios.")

anios = sorted(df.anio.astype(int).unique())
ratings = sorted(df.rating.dropna().unique())
pubs = sorted(df.publication_id.dropna().astype(int).unique())
sel_a = st.sidebar.multiselect("Año", anios, default=anios)
sel_r = st.sidebar.multiselect("Rating", ratings, default=ratings)
sel_p = st.sidebar.multiselect("Publicación (vacío = todas)", pubs)
min_com = st.sidebar.slider("Mínimo de comentarios para rankings", 50, 1000, 100, step=50)

f = df[df.anio.isin(sel_a) & df.rating.isin(sel_r)]
if sel_p:
    f = f[f.publication_id.isin(sel_p)]

total, validos = int(f.comentarios.sum()), int(f.validos.sum())
c1, c2, c3 = st.columns(3)
c1.metric("Comentarios analizados", f"{total:,}")
c2.metric("% con target >= 0,50", f"{pct(f.toxicos.sum(), validos):.2f} %")
c3.metric("Toxicidad media (target)", f"{f.suma_target.sum() / f.n_target.sum():.4f}" if f.n_target.sum() else "n/d")

# P1
m = f.groupby(["anio", "mes"], as_index=False)[["toxicos", "validos", "comentarios"]].sum()
m["periodo"] = m.anio.astype(int).astype(str) + "-" + m.mes.astype(int).astype(str).str.zfill(2)
m["pct"] = 100 * m.toxicos / m.validos
m = m.sort_values("periodo")
st.subheader("P1. Evolución mensual del % de comentarios con target >= 0,50")
st.plotly_chart(px.line(m, x="periodo", y="pct", markers=True, hover_data=["comentarios"],
                        labels={"pct": "% tóxicos", "periodo": "Mes"}), use_container_width=True)
st.caption("Los meses con pocos comentarios (ver hover) pueden mostrar porcentajes inestables.")

col_a, col_b = st.columns(2)
# P2
p = f.groupby("publication_id", as_index=False)[["toxicos", "validos", "comentarios"]].sum()
p = p[p.comentarios >= min_com]
p["pct"] = 100 * p.toxicos / p.validos
p = p.sort_values("pct", ascending=False).head(10)
p["publication_id"] = p.publication_id.astype(int).astype(str)
with col_a:
    st.subheader("P2. Top 10 publicaciones por % de toxicidad")
    st.plotly_chart(px.bar(p, x="publication_id", y="pct", hover_data=["comentarios"],
                           labels={"pct": "% tóxicos", "publication_id": "Publicación"}),
                    use_container_width=True)
# P3
r = f.groupby("rating", as_index=False)[["toxicos", "validos", "comentarios"]].sum()
r["pct"] = 100 * r.toxicos / r.validos
with col_b:
    st.subheader("P3. % de toxicidad por rating")
    st.plotly_chart(px.bar(r, x="rating", y="pct", hover_data=["comentarios"],
                           labels={"pct": "% tóxicos", "rating": "Rating"}), use_container_width=True)
    st.caption("Asociación descriptiva; no implica error de moderación.")

with st.expander("Datos del ranking (P2)"):
    st.dataframe(p, use_container_width=True)
